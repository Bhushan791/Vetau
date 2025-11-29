import { Router } from "express";
import { verifyJWT } from "../../middlewares/auth.middleware.js";
import { verifyAdmin } from "../../middlewares/auth.middleware.js";

// Import all admin controllers
import * as dashboard from "../../controllers/admin/dashboard.controller.js";
import * as userMgmt from "../../controllers/admin/userManagement.controller.js";
import * as postMgmt from "../../controllers/admin/postManagement.controller.js";
import * as claimsAnalytics from "../../controllers/admin/claimsAnalytics.controller.js";
import * as reports from "../../controllers/admin/reports.controller.js";

const router = Router();

// Apply auth middleware to ALL admin routes
router.use(verifyJWT);
router.use(verifyAdmin);

// ===== DASHBOARD =====
router.get("/dashboard/stats", dashboard.getDashboardStats);
router.get("/dashboard/charts", dashboard.getDashboardCharts);
router.get("/dashboard/activity", dashboard.getRecentActivity);

// ===== USER MANAGEMENT =====
router.get("/users", userMgmt.getAllUsers);
router.get("/users/:userId", userMgmt.getUserDetails);
router.patch("/users/:userId/ban", userMgmt.banUser);
router.patch("/users/:userId/unban", userMgmt.unbanUser);
router.delete("/users/:userId", userMgmt.softDeleteUser);
router.get("/users/export/csv", userMgmt.exportUsers);

// ===== POST MANAGEMENT =====
router.get("/posts", postMgmt.getAllPostsAdmin);
router.get("/posts/:postId", postMgmt.getPostDetailsAdmin);
router.delete("/posts/:postId", postMgmt.softDeletePost);
router.get("/posts/export/csv", postMgmt.exportPosts);

// ===== CLAIMS ANALYTICS =====
router.get("/claims/analytics", claimsAnalytics.getClaimsAnalytics);
router.get("/claims/trend", claimsAnalytics.getClaimsTrend);
router.get("/claims/top-users", claimsAnalytics.getTopClaimers);

// ===== REPORTS =====
router.get("/reports/users", reports.getUserAnalytics);
router.get("/reports/posts", reports.getPostAnalytics);
router.get("/reports/revenue", reports.getRevenueAnalytics);
router.get("/reports/engagement", reports.getEngagementAnalytics);

export default router;