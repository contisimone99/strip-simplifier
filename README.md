# strip-simplifier
This script is designed to simplify the process of partially stripping an executable by removing specific global variables and functions. It offers a flexible, error-checked solution that can be easily integrated into your build or testing workflow.

## Features

- **Selective Symbol Stripping:**
  Remove only the specified symbols (functions and/or global variables) from your executable using `strip` and `objcopy`.

- **Complete Strip Fallback:**
  If no symbol lists are provided, the script will automatically perform a full strip of the executable.

- **Error Handling:**
  The script checks the outcome of every command (such as `cp`, `strip`, `objcopy`, and `mv`) and exits with a clear error message if something goes wrong.

- **Backup Creation:**
  A backup of the original executable is created before any modifications, ensuring you can always revert if needed.

- **Backup restoration:**
  The backup created from the script gets restored in order to revert all the modifications made.
  
- **Command-Line Help:**
  Detailed help is available via the `-h` option, which explains how to use the script and its various options.

- **Future Enhancements:**
  The README also discusses potential improvements like interactive mode, automatic symbol detection and detailed logging.

## Usage

To run the script, you must provide the executable file you want to strip. Optionally, you can also specify files that list the functions and/or global variables to be removed.

### Command-Line Options

- `-e executable`
  **(Required)** Specifies the name (or path) of the executable to be processed.

- `-f functions_file` 
  **(Optional)** A file containing the names of functions to be stripped from the executable.

- `-g globals_file`
  **(Optional)** A file containing the names of global variables to be stripped from the executable.

- `-r`
  **(Optional)** Restore the previously made backup executable in order to revert the strip operation. If it does not find a *.backup file in the current folder it throws an error message.

- `-h`
  Displays a help message detailing the usage of the script.

### Examples

1. **Selective Strip:**

   If you have two files, `functions.txt` and `globals.txt`, listing the symbols you want to remove:

   ```bash
   ./strip-simplifier.sh -e my_executable -f functions.txt -g globals.txt
   ```

2. **Strip Only Functions:**

   ```bash
   ./strip-simplifier.sh -e my_executable -f functions.txt
   ```

3. **Strip Only Globals:**

   ```bash
   ./strip-simplifier.sh -e my_executable -g globals.txt
   ```

4. **Full Strip (No Symbol Files Provided):**

   ```bash
   ./strip-simplifier.sh -e my_executable
   ```
5. **Restore the executable**
   ```bash
    ./strip-simplifier.sh -e my_executable -r
   ```
## How to Test

1. **Compile the Example:**  
   Compile the provided `example.c` with debugging symbols:
   ```bash
   gcc -g -o example example.c
   ```

2. **Run the Script:**  
   Use the provided `strip-simplifier.sh` script along with `globals.txt` and `functions.txt` to remove the specified symbols:
   ```bash
   ./strip-simplifier.sh -e example -g globals.txt -f functions.txt
   ```

3. **Verify the Result:**  
   Check the remaining symbols using `nm`:
   ```bash
   nm example | grep -E "global_var1|global_var2|function_to_strip|another_function_to_strip"
   ```
    You should see that the functions defined in the regex are not present, while if you use `nm example | grep function_to_keep` you will see that `function_to_keep` is still present, while the symbols listed in the globals and functions files have been removed.

4. **Restore the backup**:
   You can restore the backup by doing:
   ```sh
    ./strip-simplifier.sh -e example -r
   ```
  
5. **Verify the backup**:
   If you now check the example executable:
   ```
    nm example | grep -E "global_var1|global_var2|function_to_strip|another_function_to_strip"
   ```
   You should have an output like the following:
   ```
    000000000000119d T another_function_to_strip
    0000000000001169 T function_to_strip
    0000000000004010 D global_var1
    0000000000004014 D global_var2
   ```
   Which means that we correctly restored the backup from the stripped file.
## Technical Details

The script utilizes both `strip` and `objcopy` to remove symbols. This dual approach ensures a higher level of confidence that the specified symbols are removed from the executable. It uses `nm` to display the symbols before and after the stripping process, which helps in verifying the changes.

### Error Handling

Each critical operation (like copying the executable, stripping symbols, and renaming temporary files) is wrapped in a function that checks the command's exit status. If any command fails, the script outputs an error message and terminates, preventing further modifications on a potentially unstable binary.

### Backup & Recovery

Before any modifications are made, the script creates a backup of the original executable by appending `.backup` to its name. This safeguard ensures that you can always revert to the original version if the strip operation does not yield the expected result.

### Future Considerations

While the script currently relies on user-provided files for symbol names, there are ideas for further improvements:
- [ ] **Interactive Mode:** Prompt the user to decide on stripping symbols if no files are provided.
- [ ] **Automatic Symbol Detection:** Analyze the output of tools like `nm` or `readelf` to attempt an automatic distinction between library symbols and user-defined symbols. Note that this is challenging—especially for static executables—and might lead to false positives or negatives.
- [ ] **Logging:** Create a detailed log file that tracks every step and command output for troubleshooting purposes.
- [x] **Backup Restoration:** An option to automatically restore the backup if the stripping process fails or if the user wishes to revert the changes.

## Contributing

Contributions are welcome! If you have ideas for new features, improvements, or bug fixes, please open an issue or submit a pull request. Collaboration is encouraged to make this tool even more robust and user-friendly.

## License

Distributed under the MIT License. See the [LICENSE](LICENSE) file for more details.
