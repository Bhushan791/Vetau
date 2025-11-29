import mongoose from "mongoose";
import bcrypt from "bcrypt";
import { User } from "./models/user.model.js";
import { Category } from "./models/category.model.js";
import { Post } from "./models/post.model.js";
import { v4 as uuidv4 } from "uuid";

// ============================================
// REALISTIC NEPALI USER DATA
// ============================================
const realisticUsers = [
  { firstName: "Rajesh", lastName: "Sharma", location: "Thamel, Kathmandu" },
  { firstName: "Sita", lastName: "Thapa", location: "Patan Dhoka, Lalitpur" },
  { firstName: "Amit", lastName: "Shrestha", location: "New Road, Kathmandu" },
  { firstName: "Priya", lastName: "Rai", location: "Boudha Stupa Area" },
  { firstName: "Suresh", lastName: "Gurung", location: "Pulchowk Campus" },
  { firstName: "Anita", lastName: "Tamang", location: "Durbar Square, Bhaktapur" },
  { firstName: "Bikash", lastName: "Magar", location: "Kathmandu University, Dhulikhel" },
  { firstName: "Kritika", lastName: "Karki", location: "Tribhuvan International Airport" },
  { firstName: "Ramesh", lastName: "Adhikari", location: "Pashupati Area" },
  { firstName: "Sunita", lastName: "Basnet", location: "Swayambhu" },
  { firstName: "Deepak", lastName: "Pandey", location: "IOE Pulchowk" },
  { firstName: "Pooja", lastName: "Poudel", location: "Civil Mall, Sundhara" },
  { firstName: "Anil", lastName: "Ghimire", location: "City Centre, Kamalpokhari" },
  { firstName: "Shreya", lastName: "Neupane", location: "Bhrikutimandap" },
  { firstName: "Kamal", lastName: "Khadka", location: "Ratna Park" },
  { firstName: "Rina", lastName: "Bhattarai", location: "Basantapur" },
  { firstName: "Nabin", lastName: "Dahal", location: "Koteshwor" },
  { firstName: "Sabina", lastName: "Koirala", location: "Baneshwor" },
  { firstName: "Dinesh", lastName: "Oli", location: "Maharajgunj" },
  { firstName: "Mina", lastName: "Acharya", location: "Thamel, Kathmandu" },
  { firstName: "Santosh", lastName: "Bhandari", location: "New Road, Kathmandu" },
  { firstName: "Kamala", lastName: "Regmi", location: "Patan Dhoka, Lalitpur" },
  { firstName: "Prabin", lastName: "Subedi", location: "Boudha Stupa Area" },
  { firstName: "Gita", lastName: "Joshi", location: "Pulchowk Campus" },
  { firstName: "Krishna", lastName: "Limbu", location: "Durbar Square, Bhaktapur" },
];

// ============================================
// HIGH-QUALITY REALISTIC POST DATA
// ============================================
const lostItems = [
  {
    itemName: "iPhone 14 Pro Max",
    description: "Lost my space black iPhone 14 Pro Max (256GB) near the Boudha Stupa area around 3 PM yesterday. It has a navy blue leather case with my initials 'RS' engraved on it. The phone contains very important family photos and work data. Offering a generous reward for its safe return. Please contact me if you find it.",
    category: "electronics",
    tags: ["iphone", "phone", "electronics", "boudha"],
    rewardAmount: 5000,
    images: ["https://images.unsplash.com/photo-1592286927505-2c0b5e3a6e18?w=800"],
  },
  {
    itemName: "Brown Leather Wallet",
    description: "Lost my brown leather wallet containing citizenship card, driving license, credit cards, and some cash near Durbar Square, Bhaktapur yesterday evening. The wallet is from Tommy Hilfiger brand and has sentimental value as it was a gift from my late father. Please help me find it.",
    category: "bags",
    tags: ["wallet", "documents", "leather", "bhaktapur"],
    rewardAmount: 3000,
    images: ["https://images.unsplash.com/photo-1627123424574-724758594e93?w=800"],
  },
  {
    itemName: "Gold Wedding Ring",
    description: "Lost my 22K gold wedding ring with diamond stones at City Centre, Kamalpokhari. It slipped off my finger in the parking area. This ring has immense emotional value as it was my grandmother's. Offering substantial reward. Please contact if found.",
    category: "jewelry",
    tags: ["ring", "gold", "jewelry", "wedding"],
    rewardAmount: 10000,
    images: ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800"],
  },
  {
    itemName: "Black HP Laptop Bag",
    description: "Lost my black HP laptop bag containing Dell Latitude laptop, charger, important work documents, and USB drives at IOE Pulchowk campus library on Thursday. The bag has a red keychain attached. Urgent - contains critical project files. Good reward offered.",
    category: "bags",
    tags: ["laptop", "bag", "electronics", "pulchowk"],
    rewardAmount: 4000,
    images: ["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800"],
  },
  {
    itemName: "House Keys with Panda Keychain",
    description: "Lost my bunch of house keys with a distinctive black and white panda keychain near Ratna Park bus stop this morning. The keychain has 'Best Friend' written on it. Keys include house main door, room, and bike keys. Please help!",
    category: "keys",
    tags: ["keys", "keychain", "house", "ratna-park"],
    rewardAmount: 1500,
    images: ["https://images.unsplash.com/photo-1582139329536-e7284fece509?w=800"],
  },
  {
    itemName: "Blue Nike Backpack",
    description: "Lost my blue Nike backpack with white logo at Tribhuvan International Airport departure hall yesterday. Contains textbooks, notebooks, student ID card, and my passport. Extremely urgent! Please contact immediately if found. Generous reward.",
    category: "bags",
    tags: ["backpack", "nike", "airport", "student"],
    rewardAmount: 6000,
    images: ["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800", "https://images.unsplash.com/photo-1491637639811-60e2756cc1c7?w=800"],
  },
  {
    itemName: "Silver MacBook Air",
    description: "Lost my silver MacBook Air M1 (2020) at Civil Mall food court on Sunday afternoon. It was in a gray sleeve case with stickers. Contains important client work and personal data. Please help me recover it. Offering good reward for safe return.",
    category: "electronics",
    tags: ["macbook", "laptop", "apple", "civil-mall"],
    rewardAmount: 7000,
    images: ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800"],
  },
  {
    itemName: "Passport and Citizenship Card",
    description: "Lost my maroon passport folder containing Nepali passport, citizenship card, and some USD currency near Pashupati temple area during morning visit. These documents are extremely important for my upcoming travel. Urgent! High reward offered.",
    category: "documents",
    tags: ["passport", "documents", "citizenship", "pashupati"],
    rewardAmount: 8000,
    images: ["https://images.unsplash.com/photo-1578774103491-dc9011e1ce19?w=800"],
  },
  {
    itemName: "Canon DSLR Camera",
    description: "Lost my Canon EOS 90D DSLR camera with 18-135mm lens at Swayambhu Stupa during photography session yesterday evening. Camera bag is black with Canon branding. Contains my entire portfolio work. Please help me find it. Substantial reward.",
    category: "cameras",
    tags: ["camera", "dslr", "canon", "swayambhu"],
    rewardAmount: 12000,
    images: ["https://images.unsplash.com/photo-1606980707986-8ba9bbf3e0e8?w=800", "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800"],
  },
  {
    itemName: "Student ID and Bus Pass",
    description: "Lost my Kathmandu University student ID card along with monthly bus pass near KU Hospital bus stop this morning. The ID has my photo and the pass is valid till next month. Need urgently for exam entry. Small reward offered.",
    category: "cards",
    tags: ["student-id", "cards", "ku", "bus-pass"],
    rewardAmount: 1000,
    images: ["https://images.unsplash.com/photo-1614680376593-902f74cf0d41?w=800"],
  },
  {
    itemName: "Black Leather Jacket",
    description: "Lost my black leather jacket (size L) at Basantapur Durbar Square last Saturday night. Has inside pocket with my name tag 'Deepak Pandey'. The jacket was a birthday gift and means a lot to me. Offering reward for its return.",
    category: "clothing",
    tags: ["jacket", "leather", "clothing", "basantapur"],
    rewardAmount: 2500,
    images: ["https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800"],
  },
  {
    itemName: "Silver Titan Watch",
    description: "Lost my silver Titan automatic watch with brown leather strap near Baneshwor traffic signal. The watch has some scratches on the back and my father's name engraved. Family heirloom - very sentimental value. Good reward for return.",
    category: "jewelry",
    tags: ["watch", "titan", "jewelry", "baneshwor"],
    rewardAmount: 4500,
    images: ["https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=800"],
  },
  {
    itemName: "Red Mountain Bike",
    description: "Lost my red Hero Sprint mountain bike (21-speed) near Maharajgunj Chakrapath on Monday evening. It was locked but someone must have taken it. Bike has distinctive white handlebar tape and a water bottle holder. Please help recover it.",
    category: "sports equipment",
    tags: ["bike", "bicycle", "sports", "maharajgunj"],
    rewardAmount: 5500,
    images: ["https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=800"],
  },
];

const foundItems = [
  {
    itemName: "Samsung Galaxy S22",
    description: "Found this Samsung Galaxy S22 in blue color near Thamel Chowk yesterday evening around 7 PM. The phone is locked with pattern. Found it on a bench near the street. Owner can contact me by describing the lock screen wallpaper or any identifying app icons.",
    category: "electronics",
    tags: ["samsung", "phone", "electronics", "thamel"],
    images: ["https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800", "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800"],
  },
  {
    itemName: "Black Leather Wallet",
    description: "Found a black leather wallet near New Road yesterday containing some cash, credit cards, and ID photos. Keeping it safe. The wallet seems to belong to someone from Lalitpur area based on the cards. Please contact with proper identification to claim.",
    category: "bags",
    tags: ["wallet", "leather", "documents", "new-road"],
    images: ["https://images.unsplash.com/photo-1627123424574-724758594e93?w=800"],
  },
  {
    itemName: "Car Keys with Toyota Logo",
    description: "Found Toyota car keys with remote and two house keys attached near Koteshwor bridge this morning. The keychain has a small Buddha charm. Keys are currently with me. Owner can contact by describing the car model or house key colors.",
    category: "keys",
    tags: ["keys", "car", "toyota", "koteshwor"],
    images: ["https://images.unsplash.com/photo-1582139329536-e7284fece509?w=800"],
  },
  {
    itemName: "Ladies Gold Earrings",
    description: "Found a pair of gold earrings with small ruby stones near Patan Dhoka Mangal Bazaar on Sunday. They were lying on the ground near the fountain. Appear to be genuine gold and quite valuable. Rightful owner please contact with purchase receipt or photos.",
    category: "jewelry",
    tags: ["earrings", "gold", "jewelry", "patan"],
    images: ["https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800"],
  },
  {
    itemName: "Purple JanSport Backpack",
    description: "Found purple JanSport backpack containing notebooks, pens, and a water bottle at Pulchowk Bus Park yesterday afternoon. No ID inside but has 'Class 12' written on notebooks. Student owner please contact to claim your bag and belongings.",
    category: "bags",
    tags: ["backpack", "jansport", "student", "pulchowk"],
    images: ["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800", "https://images.unsplash.com/photo-1577733966973-d680bffd2e80?w=800"],
  },
  {
    itemName: "Prescription Eyeglasses",
    description: "Found black rectangular prescription glasses in a brown case near Boudha Stupa main entrance on Friday morning. The glasses are for nearsightedness (negative power). Owner must be having difficulty without them. Please contact to collect.",
    category: "accessories",
    tags: ["glasses", "eyeglasses", "accessories", "boudha"],
    images: ["https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=800"],
  },
  {
    itemName: "Children's School Bag",
    description: "Found a small red school bag with cartoon characters near Bhrikutimandap park this morning. Contains lunch box, pencil case, and school books with name partially visible. Concerned about the child. Parents please contact immediately to collect.",
    category: "bags",
    tags: ["school-bag", "children", "student", "bhrikutimandap"],
    images: ["https://images.unsplash.com/photo-1577733966973-d680bffd2e80?w=800"],
  },
  {
    itemName: "Blue Umbrella",
    description: "Found good quality blue automatic umbrella at City Centre parking area yesterday during rain. Has a wooden handle and appears quite new. Left behind by someone. Keeping it at security desk. Owner can collect by describing the brand name.",
    category: "accessories",
    tags: ["umbrella", "accessories", "city-centre"],
    images: ["https://images.unsplash.com/photo-1584930699959-d46a5edcac16?w=800"],
  },
  {
    itemName: "ID Card and ATM Cards",
    description: "Found someone's citizenship ID card along with two ATM cards (NMB and Kumari Bank) near Ratna Park ATM booth this morning. Keeping them safe. Owner please contact by mentioning the name on ID for verification before claiming.",
    category: "cards",
    tags: ["id-card", "atm", "documents", "ratna-park"],
    images: ["https://images.unsplash.com/photo-1614680376593-902f74cf0d41?w=800"],
  },
  {
    itemName: "White Airpods Pro",
    description: "Found white Apple AirPods Pro with charging case near IOE Pulchowk canteen area on Wednesday. Case has slight scratches. Connected briefly and shows owner's device name. Please contact with proof of purchase or serial number to claim.",
    category: "electronics",
    tags: ["airpods", "apple", "electronics", "pulchowk"],
    images: ["https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=800", "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800"],
  },
  {
    itemName: "Women's Gold Ring",
    description: "Found beautiful gold ring with initials 'S.T.' engraved inside near Swayambhu parking area last Saturday. Ring appears to be wedding or engagement ring based on the design. Owner please contact with description of the stone or engraving details.",
    category: "jewelry",
    tags: ["ring", "gold", "jewelry", "swayambhu"],
    images: ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800"],
  },
  {
    itemName: "Gray Nike Sports Shoes",
    description: "Found pair of gray Nike running shoes (appears size 9-10) near Baneshwor sports ground yesterday evening. Shoes are in good condition and seem barely used. Someone might have forgotten after exercise. Contact to claim with shoe size confirmation.",
    category: "clothing",
    tags: ["shoes", "nike", "sports", "baneshwor"],
    images: ["https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800"],
  },
];

// ============================================
// SEED FUNCTION
// ============================================
async function seedDatabase() {
  try {
    console.log("🌱 Starting production-grade database seeding...\n");

    // Clear existing data (preserve admins)
    await Category.deleteMany({});
    await Post.deleteMany({});
    await User.deleteMany({ role: { $ne: "admin" } });
    console.log("✅ Cleared existing dummy data (preserved admins)\n");

    // Check for admin users
    const adminUsers = await User.find({ role: "admin" });
    if (adminUsers.length === 0) {
      console.log("⚠️  No admin users found. Please run admin seed first!");
      return;
    }

    // ============================================
    // SEED CATEGORIES
    // ============================================
    const categories = [
      { categoryId: "cat_electronics", name: "electronics", description: "Phones, laptops, tablets, and other electronic devices", icon: "📱" },
      { categoryId: "cat_documents", name: "documents", description: "IDs, passports, licenses, certificates", icon: "📄" },
      { categoryId: "cat_bags", name: "bags", description: "Backpacks, handbags, wallets, luggage", icon: "🎒" },
      { categoryId: "cat_keys", name: "keys", description: "House keys, car keys, key chains", icon: "🔑" },
      { categoryId: "cat_jewelry", name: "jewelry", description: "Rings, necklaces, watches, bracelets", icon: "💍" },
      { categoryId: "cat_clothing", name: "clothing", description: "Jackets, shoes, hats, scarves", icon: "👕" },
      { categoryId: "cat_accessories", name: "accessories", description: "Glasses, sunglasses, umbrellas", icon: "👓" },
      { categoryId: "cat_sports", name: "sports equipment", description: "Bikes, balls, gym equipment", icon: "⚽" },
      { categoryId: "cat_cameras", name: "cameras", description: "Digital cameras, GoPros, lenses", icon: "📷" },
      { categoryId: "cat_cards", name: "cards", description: "Credit cards, student IDs, membership cards", icon: "💳" },
    ];

    await Category.insertMany(categories);
    console.log(`✅ Seeded ${categories.length} categories\n`);

    // ============================================
    // SEED USERS
    // ============================================
    const hashedPassword = await bcrypt.hash("password123", 10);
    const users = [];

    for (let i = 0; i < realisticUsers.length; i++) {
      const userData = realisticUsers[i];
      const username = `${userData.firstName.toLowerCase()}${userData.lastName.toLowerCase()}`;
      
      users.push({
        userId: uuidv4(),
        fullName: `${userData.firstName} ${userData.lastName}`,
        username: username,
        email: `${username}@gmail.com`,
        password: hashedPassword,
        address: userData.location,
        profileImage: `https://i.pravatar.cc/300?img=${i + 1}`,
        authType: "normal",
        role: "user",
        status: "active",
        fcmToken: null,
        lastActive: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
      });
    }

    const createdUsers = await User.insertMany(users);
    console.log(`✅ Seeded ${createdUsers.length} users with realistic data\n`);

    // ============================================
    // SEED POSTS
    // ============================================
    const posts = [];
    const allUsers = [...adminUsers, ...createdUsers];

    // Add LOST posts
    lostItems.forEach((item, index) => {
      const user = allUsers[index % allUsers.length];
      posts.push({
        postId: uuidv4(),
        userId: user._id,
        type: "lost",
        itemName: item.itemName,
        description: item.description,
        location: {
          name: user.address || "Kathmandu, Nepal",
          coordinates: [
            85.3240 + (Math.random() - 0.5) * 0.1,
            27.7172 + (Math.random() - 0.5) * 0.1,
          ],
        },
        category: item.category,
        tags: item.tags,
        images: item.images,
        rewardAmount: item.rewardAmount,
        status: "active",
        isAnonymous: Math.random() > 0.7,
        totalClaims: Math.floor(Math.random() * 3),
        totalComments: Math.floor(Math.random() * 5),
        createdAt: new Date(Date.now() - Math.random() * 15 * 24 * 60 * 60 * 1000),
      });
    });

    // Add FOUND posts
    foundItems.forEach((item, index) => {
      const user = allUsers[(index + 13) % allUsers.length];
      posts.push({
        postId: uuidv4(),
        userId: user._id,
        type: "found",
        itemName: item.itemName,
        description: item.description,
        location: {
          name: user.address || "Kathmandu, Nepal",
          coordinates: [
            85.3240 + (Math.random() - 0.5) * 0.1,
            27.7172 + (Math.random() - 0.5) * 0.1,
          ],
        },
        category: item.category,
        tags: item.tags,
        images: item.images,
        rewardAmount: 0,
        status: "active",
        isAnonymous: Math.random() > 0.8,
        totalClaims: Math.floor(Math.random() * 4),
        totalComments: Math.floor(Math.random() * 8),
        createdAt: new Date(Date.now() - Math.random() * 20 * 24 * 60 * 60 * 1000),
      });
    });

    const createdPosts = await Post.insertMany(posts);
    console.log(`✅ Seeded ${createdPosts.length} posts (${lostItems.length} lost, ${foundItems.length} found)\n`);

    // ============================================
    // SUMMARY
    // ============================================
    console.log("🎉 Production-grade seeding completed successfully!\n");
    console.log("📊 SUMMARY:");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log(`   Categories: ${categories.length}`);
    console.log(`   Users: ${createdUsers.length} (+ ${adminUsers.length} admins preserved)`);
    console.log(`   Posts: ${createdPosts.length} (${lostItems.length} lost + ${foundItems.length} found)`);
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    console.log("🔐 TEST CREDENTIALS:");
    console.log("   Email: rajeshsharma@gmail.com");
    console.log("   Password: password123\n");
    console.log("✨ All images are high-quality from Unsplash");
    console.log("✨ All users have @gmail.com addresses");
    console.log("✨ FCM tokens set to null (as requested)\n");

  } catch (error) {
    console.error("❌ Error seeding database:", error);
    throw error;
  }
}

export default seedDatabase;