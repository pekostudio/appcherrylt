# Keep MediaStore related classes
-keep class android.provider.MediaStore** { *; }
-keep class android.media** { *; }

# Keep content resolver and content provider classes
-keep class android.content.ContentResolver { *; }
-keep class android.content.ContentProvider { *; }
-keep class android.content.ContentValues { *; }
-keep class android.content.ContentUris { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler** { *; }

# Keep MediaStore specific classes
-keep class android.provider.MediaStore$Audio** { *; }
-keep class android.provider.MediaStore$Images** { *; }
-keep class android.provider.MediaStore$Video** { *; }
-keep class android.provider.MediaStore$Files** { *; }

# Keep Uri classes
-keep class android.net.Uri { *; }
