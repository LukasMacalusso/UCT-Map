using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class StudentHandler
{
    private readonly IMeetingRepository _meetingRepository;

    public StudentHandler(IMeetingRepository meetingRepository) { _meetingRepository = meetingRepository; }

    public async Task<ErrorOr<StudentMeetingsDto>> GetMeetingsAsync(Guid studentRefId, DateTime from, DateTime to, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanAccess(studentRefId)) return Error.Forbidden(description: "Only the student or an administrator can see these meetings.");
        if (to <= from) return Error.Validation(description: "The 'to' parameter must be later than 'from'.");
        var meetings = await _meetingRepository.GetByStudentAsync(studentRefId, from, to, cancellationToken);
        var dto = new StudentMeetingsDto(studentRefId, from, to, meetings.Count, meetings.Select(MeetingDto.FromEntity).ToList());
        return dto;
    }
}
