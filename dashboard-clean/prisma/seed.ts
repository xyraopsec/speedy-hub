import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
const games = [
  { name: "Driving Empire", universeId: BigInt(1202096104), placeId: BigInt(3357602286), order: 0 },
  { name: "Greenville", universeId: BigInt(371263894), placeId: BigInt(891852901), order: 1 },
  { name: "Southwest Florida", universeId: BigInt(1223555379), placeId: BigInt(1948063469), order: 2 },
  { name: "Ultimate Driving", universeId: BigInt(5370313807), placeId: BigInt(5481977539), order: 3 },
  { name: "Vehicle Simulator", universeId: BigInt(128894195), placeId: BigInt(1713919481), order: 4 },
  { name: "Pacifico 2", universeId: BigInt(8710553023), placeId: BigInt(8710555530), order: 5 },
  { name: "Midnight Racing: Tokyo", universeId: BigInt(142823291), placeId: BigInt(8668473321), order: 6 },
  { name: "Car Crushers 2", universeId: BigInt(654732683), placeId: BigInt(654732683), order: 7 },
  { name: "Vehicle Legends", universeId: BigInt(1480782352), placeId: BigInt(4566572536), order: 8 },
  { name: "ER:LC", universeId: BigInt(2534724415), placeId: BigInt(2534724715), order: 9 },
  { name: "Taxi Boss", universeId: BigInt(1047336831), placeId: BigInt(6690848885), order: 10 },
  { name: "Drift Paradise", universeId: BigInt(13322300479), placeId: BigInt(13322300479), order: 11 },
  { name: "Car Dealership Tycoon", universeId: BigInt(605887098), placeId: BigInt(1554960397), order: 12 },
  { name: "Jailbreak", universeId: BigInt(606849621), placeId: BigInt(606849621), order: 13 },
  { name: "A Dusty Trip", universeId: BigInt(5650396773), placeId: BigInt(16389395869), order: 14 },
  { name: "Driving Simulator", universeId: BigInt(4646475446), placeId: BigInt(4727715908), order: 15 },
  { name: "Automotive Tycoon", universeId: BigInt(3108293283), placeId: BigInt(3286570058), order: 16 },
  { name: "Moto Trackday Project", universeId: BigInt(10570812351), placeId: BigInt(10570812351), order: 17 },
  { name: "Motorcycle Mayhem", universeId: BigInt(891380602), placeId: BigInt(891380733), order: 18 },
  { name: "Car Factory Tycoon", universeId: BigInt(2167018139), placeId: BigInt(2167018139), order: 19 },
];
async function main() {
  for (const g of games) {
    await prisma.game.upsert({ where: { universeId: g.universeId }, update: { name: g.name, placeId: g.placeId, order: g.order }, create: g });
  }
  console.log("Seeded 20 games");
}
main().finally(() => prisma.$disconnect());
