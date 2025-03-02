import os
import re

def remove_comments_from_dart_file(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        content = file.read()
    
    # حذف کامنت‌های چندخطی /* ... */
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    
    # حذف کامنت‌های تک‌خطی // تا انتهای خط
    content = re.sub(r"//.*", "", content)
    
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                remove_comments_from_dart_file(file_path)
                print(f"Processed: {file_path}")

if __name__ == "__main__":
    lib_path = os.path.join(os.getcwd(), "lib")
    if os.path.exists(lib_path):
        process_directory(lib_path)
        print("All Dart files processed successfully.")
    else:
        print("Error: 'lib' directory not found.")
