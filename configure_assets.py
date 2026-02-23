import os
import json

app_dir = "/Users/Apple/Documents/Adi_project/KineprintApp2.0.swiftpm/Assets.xcassets"
if not os.path.exists(app_dir):
    print("No Assets")
    exit(0)

for dir_name in os.listdir(app_dir):
    if dir_name.endswith(".imageset"):
        img_name = dir_name.replace(".imageset", "") + ".png"
        full_dir = os.path.join(app_dir, dir_name)
        
        contents = {
          "images" : [
            {
              "idiom" : "universal",
              "filename" : img_name,
              "scale" : "1x"
            },
            {
              "idiom" : "universal",
              "scale" : "2x"
            },
            {
              "idiom" : "universal",
              "scale" : "3x"
            }
          ],
          "info" : {
            "version" : 1,
            "author" : "xcode"
          }
        }
        
        with open(os.path.join(full_dir, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
            
print("Done")
