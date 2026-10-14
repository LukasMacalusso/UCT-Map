using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Campus.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBuildingScheduleAndServices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Schedule",
                table: "Buildings",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<List<string>>(
                name: "Services",
                table: "Buildings",
                type: "text[]",
                nullable: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Schedule",
                table: "Buildings");

            migrationBuilder.DropColumn(
                name: "Services",
                table: "Buildings");
        }
    }
}
