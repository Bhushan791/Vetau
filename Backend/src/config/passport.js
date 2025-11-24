import dotenv from "dotenv";
dotenv.config(); // <-- ensure env variables are loaded

import passport from "passport";
import { Strategy as GoogleStrategy } from "passport-google-oauth20";
import { User } from "../models/user.model.js";
import { v4 as uuidv4 } from "uuid";


passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails[0].value;
        let user = await User.findOne({ email });

        if (user) return done(null, user);

        const username = email.split("@")[0] + "_" + uuidv4().slice(0, 6);

        user = await User.create({
          userId: uuidv4(),
          fullName: profile.displayName,
          username: username.toLowerCase(),
          email: email.toLowerCase(),
          profileImage: profile.photos[0]?.value || "",
          authType: "google",
        });

        return done(null, user);
      } catch (error) {
        return done(error, null);
      }
    }
  )
);

export default passport;
