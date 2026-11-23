using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Campus.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderingAndNullableStructureCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Structures_Categories_CategoryId",
                table: "Structures");

            migrationBuilder.AlterColumn<Guid>(
                name: "CategoryId",
                table: "Structures",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<int>(
                name: "Order",
                table: "CategoryGroups",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Order",
                table: "Categories",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddForeignKey(
                name: "FK_Structures_Categories_CategoryId",
                table: "Structures",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Structures_Categories_CategoryId",
                table: "Structures");

            migrationBuilder.DropColumn(
                name: "Order",
                table: "CategoryGroups");

            migrationBuilder.DropColumn(
                name: "Order",
                table: "Categories");

            migrationBuilder.AlterColumn<Guid>(
                name: "CategoryId",
                table: "Structures",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Structures_Categories_CategoryId",
                table: "Structures",
                column: "CategoryId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
