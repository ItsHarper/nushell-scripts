export const takeoutStateFilename = "takeoutState.nuon"
export const takeoutStateFilePath = $"/run/media/harper/X400/MOEGoogleAccountTakeout/($takeoutStateFilename)"
export const photosFolder = "/run/media/harper/X400/MOEGoogleAccountTakeout/Photos/"

export const PROGRESS_NONE = "none"
export const PROGRESS_DOWNLOADED = "downloaded"
export const PROGRESS_EXTRACTED = "extracted"
export const PROGRESS_EXTRACTED_AND_DELETED = "extractedAndDeleted"
export const PROGRESS_VALUES_NOT_EXTRACTED = [ $PROGRESS_NONE, $PROGRESS_DOWNLOADED ]
export const PROGRESS_VALUES_EXTRACTED = [ $PROGRESS_EXTRACTED, $PROGRESS_EXTRACTED_AND_DELETED ]

export const TYPE_GENERAL = "general"
export const TYPE_PHOTOS = "photos";
export const VALID_TYPES = [ $TYPE_GENERAL, $TYPE_PHOTOS ]

export const EXTENSION_ZIP = "zip"
export const EXTENSION_TAR_GZ = "tar.gz";
export const VALID_EXTENSIONS = [ $EXTENSION_ZIP, $EXTENSION_TAR_GZ ]
