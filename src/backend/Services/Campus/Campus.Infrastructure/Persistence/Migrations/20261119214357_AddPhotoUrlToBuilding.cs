using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Campus.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPhotoUrlToBuilding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PhotoUrl",
                table: "Buildings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PhotoUrl",
                table: "Buildings");
        }
    }
}
