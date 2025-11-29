// CREATE NEW FILE
import { User } from "../models/user.model.js";
import { v4 as uuidv4 } from "uuid";

export const seedAdmin = async () => {
  try {
    const adminExists = await User.findOne({
      email: process.env.ADMIN_EMAIL,
    });

    if (adminExists) {
      console.log("Admin already exists");
      return;
    }

    await User.create({
      userId: uuidv4(),
      fullName: "Admin",
      username: "admin",
      email: process.env.ADMIN_EMAIL,
      password: process.env.ADMIN_PASSWORD, // raw password (pre-save hook hashes it)
      role: "admin",
      authType: "normal",
      profileImage: process.env.ADMIN_PROFILE_PIC,
      status: "active",
    });

    console.log("Admin seeded successfully");
  } catch (error) {
    console.error("Admin seeding failed:", error);
  }
};
