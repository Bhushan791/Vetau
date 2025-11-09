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
        
        // Delete local file after successful upload
        fs.unlinkSync(localFilePath);
        console.log("File uploaded and local copy deleted:", localFilePath);
        
        return response;
    } catch (error) {
        console.log("Error uploading to cloudinary:", error);
        
        // Remove the locally saved temp file as the upload operation failed
        if (fs.existsSync(localFilePath)) {
            fs.unlinkSync(localFilePath);
            console.log("Local file deleted after upload failure:", localFilePath);
        }
        
        return null; // Return null instead of throwing error
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