using System;
using System.IO;
using System.Web;

namespace OMS.App_Code.Helpers
{
    public static class ImageHelper
    {
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".webp" };

        public static string SaveMenuItemImage(HttpPostedFile postedFile)
        {
            if (postedFile == null || postedFile.ContentLength == 0) return null;

            var extension = Path.GetExtension(postedFile.FileName);
            if (string.IsNullOrEmpty(extension)) throw new InvalidOperationException("Image extension is missing.");
            extension = extension.ToLowerInvariant();

            var allowed = false;
            foreach (var item in AllowedExtensions)
            {
                if (item == extension) allowed = true;
            }

            if (!allowed) throw new InvalidOperationException("Only JPG, PNG, and WEBP images are allowed.");
            if (!postedFile.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Uploaded file must be an image.");

            var relativeFolder = "~/Uploads/MenuItems/";
            var absoluteFolder = HttpContext.Current.Server.MapPath(relativeFolder);
            Directory.CreateDirectory(absoluteFolder);

            var fileName = Guid.NewGuid().ToString("N") + extension;
            var absolutePath = Path.Combine(absoluteFolder, fileName);
            postedFile.SaveAs(absolutePath);

            return VirtualPathUtility.ToAbsolute(relativeFolder + fileName);
        }
    }
}
