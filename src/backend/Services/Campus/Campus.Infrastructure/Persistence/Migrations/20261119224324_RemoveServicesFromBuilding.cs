using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Campus.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RemoveServicesFromBuilding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Services",
                table: "Buildings");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Services",
                table: "Buildings",
                type: "character varying(150)",
                maxLength: 150,
                nullable: true);
        }
    }
}
