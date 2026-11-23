FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["src/backend/Services/Incident/Incident.API/Incident.API.csproj", "Incident.API/"]
COPY ["src/backend/Services/Incident/Incident.Application/Incident.Application.csproj", "Incident.Application/"]
COPY ["src/backend/Services/Incident/Incident.Domain/Incident.Domain.csproj", "Incident.Domain/"]
COPY ["src/backend/Services/Incident/Incident.Infrastructure/Incident.Infrastructure.csproj", "Incident.Infrastructure/"]
RUN dotnet restore "Incident.API/Incident.API.csproj"

COPY ["src/backend/Services/Incident/Incident.API/", "Incident.API/"]
COPY ["src/backend/Services/Incident/Incident.Application/", "Incident.Application/"]
COPY ["src/backend/Services/Incident/Incident.Domain/", "Incident.Domain/"]
COPY ["src/backend/Services/Incident/Incident.Infrastructure/", "Incident.Infrastructure/"]

RUN dotnet publish "Incident.API/Incident.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

COPY --from=build /app/publish .


USER $APP_UID
ENTRYPOINT ["dotnet", "Incident.API.dll"]
