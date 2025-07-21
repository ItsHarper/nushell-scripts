export const progressFilePath = "/run/media/harper/X400/MOEGoogleAccountTakeout/progress.nuon"
export const photosFolder = "/run/media/harper/X400/MOEGoogleAccountTakeout/Photos/"

export const STATUS_NONE = "none"
export const STATUS_DOWNLOADED = "downloaded"
export const STATUS_EXTRACTED = "extracted"
export const STATUS_DELETED = "extractedToPhotosFolderAndDeleted"
export const SAFE_STATUSES_FOR_EXTRACTION = [ $STATUS_NONE, $STATUS_DOWNLOADED ]

export const TYPE_GENERAL = "general"
export const TYPE_PHOTOS = "photos";
export const VALID_TYPES = [ $TYPE_GENERAL, $TYPE_PHOTOS ]

export const EXTENSION_ZIP = "zip"
export const EXTENSION_TAR_GZ = "tar.gz";
export const VALID_EXTENSIONS = [ $EXTENSION_ZIP, $EXTENSION_TAR_GZ ]
