using Microsoft.AspNetCore.SignalR;

namespace Backend.Api.Hubs;

public class ElectionHub : Hub
{
    public async Task JoinElection(string electionId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"election_{electionId}");
    }

    public async Task LeaveElection(string electionId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"election_{electionId}");
    }
}
