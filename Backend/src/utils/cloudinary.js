import { v2 as cloudinary } from "cloudinary";
import fs from "fs";

// Configure cloudinary once (outside the function)
cloudinary.config({ 
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY, 
    api_secret: process.env.CLOUDINARY_API_SECRET
});

const uploadToCloudinary = async (localFilePath) => {
    try { 
        if (!localFilePath) return null;
        
        // Check if file exists before uploading
        if (!fs.existsSync(localFilePath)) {
            console.log("File does not exist:", localFilePath);
            return null;
        }
        
        // Upload file to cloudinary
        const response = await cloudinary.uploader.upload(localFilePath, { 
            resource_type: "auto"
        });
        
        console.log("File uploaded successfully:", localFilePath);
        return response;
        
    } catch (error) {
        console.log("Error uploading to cloudinary:", error);
        return null;
        
    } finally {
        // ALWAYS delete the temp file, success or failure
        if (localFilePath && fs.existsSync(localFilePath)) {
            fs.unlinkSync(localFilePath);
            console.log("✅ Temp file deleted:", localFilePath);
        }
    }
};

const deleteFromCloudinary = async (publicId) => { 
    try { 
        if (!publicId) return null;
        
        const result = await cloudinary.uploader.destroy(publicId);
        console.log("File deleted from cloudinary:", publicId);
        
        return result;
    } catch (error) { 
        console.log("Error deleting from cloudinary:", error);
        return null;
    }
};

export { uploadToCloudinary, deleteFromCloudinary };