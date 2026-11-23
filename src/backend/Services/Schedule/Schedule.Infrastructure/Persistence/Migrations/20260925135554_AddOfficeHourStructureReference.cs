using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Schedule.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOfficeHourStructureReference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "StructureRefId",
                table: "OfficeHours",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_OfficeHours_StructureRefId_DayOfWeek",
                table: "OfficeHours",
                columns: new[] { "StructureRefId", "DayOfWeek" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OfficeHours_StructureRefId_DayOfWeek",
                table: "OfficeHours");

            migrationBuilder.DropColumn(
                name: "StructureRefId",
                table: "OfficeHours");
        }
    }
}
