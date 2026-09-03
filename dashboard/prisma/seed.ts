import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
const games = [
  { name: "Driving Empire", universeId: 1202096104n, placeId: 3357602286n, order: 0 },
  { name: "Greenville", universeId: 371263894n, placeId: 891852901n, order: 1 },
  { name: "Southwest Florida", universeId: 1223555379n, placeId: 1948063469n, order: 2 },
  { name: "Ultimate Driving", universeId: 5370313807n, placeId: 5481977539n, order: 3 },
  { name: "Vehicle Simulator", universeId: 128894195n, placeId: 1713919481n, order: 4 },
  { name: "Pacifico 2", universeId: 8710553023n, placeId: 8710555530n, order: 5 },
  { name: "Midnight Racing: Tokyo", universeId: 142823291n, placeId: 8668473321n, order: 6 },
  { name: "Car Crushers 2", universeId: 654732683n, placeId: 654732683n, order: 7 },
  { name: "Vehicle Legends", universeId: 1480782352n, placeId: 4566572536n, order: 8 },
  { name: "ER:LC", universeId: 2534724415n, placeId: 2534724715n, order: 9 },
  { name: "Taxi Boss", universeId: 1047336831n, placeId: 6690848885n, order: 10 },
  { name: "Drift Paradise", universeId: 13322300479n, placeId: 13322300479n, order: 11 },
  { name: "Car Dealership Tycoon", universeId: 605887098n, placeId: 1554960397n, order: 12 },
  { name: "Jailbreak", universeId: 606849621n, placeId: 606849621n, order: 13 },
  { name: "A Dusty Trip", universeId: 5650396773n, placeId: 16389395869n, order: 14 },
  { name: "Driving Simulator", universeId: 4646475446n, placeId: 4727715908n, order: 15 },
  { name: "Automotive Tycoon", universeId: 3108293283n, placeId: 3286570058n, order: 16 },
  { name: "Moto Trackday Project", universeId: 10570812351n, placeId: 10570812351n, order: 17 },
  { name: "Motorcycle Mayhem", universeId: 891380602n, placeId: 891380733n, order: 18 },
  { name: "Car Factory Tycoon", universeId: 2167018139n, placeId: 2167018139n, order: 19 },
];
async function main() {
  for (const g of games) {
    await prisma.game.upsert({ where: { universeId: g.universeId }, update: { name: g.name, placeId: g.placeId, order: g.order }, create: g });
  }
  console.log("Seeded 20 games");
}
main().finally(() => prisma.$disconnect());
