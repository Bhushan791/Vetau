//ERROR HANDLER MIDDLEWARE
export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  
  return res.status(statusCode).json({
    success: false,
    statusCode,
    message: err.message || "Internal Server Error",
    errors: err.errors || [],
    ...(process.env.NODE_ENV === "development" && { stack: err.stack })
  });
};