import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  String? _currentElectionId;

  Future<void> connect(String electionId, Function() onMatchEnded) async {
    if (_hubConnection != null && _currentElectionId == electionId) {
      return; // Already connected to this election
    }

    await disconnect();

    _currentElectionId = electionId;

    _hubConnection = HubConnectionBuilder()
        .withUrl('http://localhost:5052/electionHub')
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('MatchEnded', (arguments) {
      print('SignalR: Match ended notification received');
      onMatchEnded();
    });

    try {
      await _hubConnection!.start();
      print('SignalR: Connected to hub');
      
      // Join the election group
      await _hubConnection!.invoke('JoinElection', args: [electionId]);
      print('SignalR: Joined election group: $electionId');
    } catch (e) {
      print('SignalR: Error connecting: $e');
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      if (_currentElectionId != null) {
        try {
          await _hubConnection!.invoke('LeaveElection', args: [_currentElectionId!]);
          print('SignalR: Left election group: $_currentElectionId');
        } catch (e) {
          print('SignalR: Error leaving group: $e');
        }
      }
      
      await _hubConnection!.stop();
      _hubConnection = null;
      _currentElectionId = null;
      print('SignalR: Disconnected');
    }
  }
}
