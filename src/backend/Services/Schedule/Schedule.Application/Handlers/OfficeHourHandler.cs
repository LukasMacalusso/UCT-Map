using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class OfficeHourHandler
{
    private readonly IOfficeHourRepository _repository;

    public OfficeHourHandler(IOfficeHourRepository repository) { _repository = repository; }

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

    public async Task<ErrorOr<OfficeHourDto>> CreateAsync(CreateOfficeHourRequest request, CancellationToken cancellationToken)
    {
        OfficeHour officeHour;
        try
        {
            officeHour = new OfficeHour(request.TeacherRefId, request.StructureRefId, request.DayOfWeek, request.StartTime, request.EndTime);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        await _repository.AddAsync(officeHour, cancellationToken);
        return OfficeHourDto.FromEntity(officeHour);
    }
}
