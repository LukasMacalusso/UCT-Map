using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class OfficeHourHandler
{
    private readonly IOfficeHourRepository _repository;
    private readonly IUnitOfWork _unitOfWork;

    public OfficeHourHandler(IOfficeHourRepository repository, IUnitOfWork unitOfWork)
    {
        _repository = repository;
        _unitOfWork = unitOfWork;
    }

    public async Task<ErrorOr<OfficeHourDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var officeHour = await _repository.GetByIdAsync(id, cancellationToken);
        if (officeHour is null) return Error.NotFound(description: $"Office hour '{id}' not found.");
        return OfficeHourDto.FromEntity(officeHour);
    }

    public async Task<ErrorOr<IEnumerable<OfficeHourDto>>> GetAllAsync(CancellationToken cancellationToken)
    {
        var officeHours = await _repository.GetAllAsync(cancellationToken);
        return ErrorOrFactory.From(officeHours.Select(OfficeHourDto.FromEntity));
    }

    public async Task<ErrorOr<IEnumerable<OfficeHourDto>>> GetByTeacherAsync(Guid teacherRefId, CancellationToken cancellationToken)
    {
        var officeHours = await _repository.GetByTeacherAsync(teacherRefId, cancellationToken);
        return ErrorOrFactory.From(officeHours.Select(OfficeHourDto.FromEntity));
    }

    public async Task<ErrorOr<OfficeHourDto>> CreateAsync(CreateOfficeHourRequest request, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanAccess(request.TeacherRefId))
            return Error.Forbidden(description: "Only the teacher or an administrator can create office hours for this teacher.");

        OfficeHour officeHour;
        try
        {
            officeHour = new OfficeHour(request.TeacherRefId, request.StructureRefId, request.DayOfWeek, request.StartTime, request.EndTime);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<OfficeHourDto>>(async () =>
            {
                var overlapping = await _repository.GetOverlappingAsync(
                    officeHour.TeacherRefId, officeHour.StructureRefId,
                    officeHour.DayOfWeek, officeHour.StartTime, officeHour.EndTime, cancellationToken);

                var conflict = DescribeConflict(officeHour, overlapping);
                if (conflict is not null) return Error.Conflict(description: conflict);

                await _repository.AddAsync(officeHour, cancellationToken);
                return OfficeHourDto.FromEntity(officeHour);
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The time slot was just taken by another request. Please try again.");
        }
    }

    private static string? DescribeConflict(OfficeHour officeHour, IReadOnlyList<OfficeHour> overlapping)
    {
        if (overlapping.Any(o => o.TeacherRefId == officeHour.TeacherRefId))
            return "The teacher already has an office hour at that time.";

        if (overlapping.Any(o => o.StructureRefId is not null && o.StructureRefId == officeHour.StructureRefId))
            return "The room already has an office hour at that time.";

        return null;
    }
}
