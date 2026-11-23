using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Campus.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryIdToBuilding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CategoryId",
                table: "Buildings",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Buildings_CategoryId",
                table: "Buildings",
                column: "CategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_Buildings_Categories_CategoryId",
                table: "Buildings",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Buildings_Categories_CategoryId",
                table: "Buildings");

            migrationBuilder.DropIndex(
                name: "IX_Buildings_CategoryId",
                table: "Buildings");

            migrationBuilder.DropColumn(
                name: "CategoryId",
                table: "Buildings");
        }
    }
}
