FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["src/backend/Services/Identity/Identity.API/Identity.API.csproj", "Identity.API/"]
COPY ["src/backend/Services/Identity/Identity.Application/Identity.Application.csproj", "Identity.Application/"]
COPY ["src/backend/Services/Identity/Identity.Domain/Identity.Domain.csproj", "Identity.Domain/"]
COPY ["src/backend/Services/Identity/Identity.Infrastructure/Identity.Infrastructure.csproj", "Identity.Infrastructure/"]
RUN dotnet restore "Identity.API/Identity.API.csproj"

COPY ["src/backend/Services/Identity/Identity.API/", "Identity.API/"]
COPY ["src/backend/Services/Identity/Identity.Application/", "Identity.Application/"]
COPY ["src/backend/Services/Identity/Identity.Domain/", "Identity.Domain/"]
COPY ["src/backend/Services/Identity/Identity.Infrastructure/", "Identity.Infrastructure/"]

RUN dotnet publish "Identity.API/Identity.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Identity.API.dll"]

