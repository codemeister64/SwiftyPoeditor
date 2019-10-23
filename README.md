# SwiftyPoeditor

SwiftyPoeditor is a Swift command-line tool for dealing with iOS/macOS localizations via [POEditor](https://poeditor.com) service.

![usage example](/Resources/Usage/1.png?raw=true)

## Installation

1. Clone repository and open project root folder in your command line
2. Run install script:

```bash
./install.sh
```
Or you can compile and install tool manually:
```bash
swift build -c release
cd .build/release
cp -f SwiftyPoeditor /usr/local/bin/SwiftyPoeditor
```
Now you able to run SwiftyPoeditor from anywhere on the command line.

## Usage

Currently, SwiftyPoeditor has two commands:

**download** - used to download specified localization from POEditor service.

**upload** - used to upload new localization-terms to POEditor service

```bash
// simple usage
SwiftyPoeditor download
SwiftyPoeditor upload

// or add --help flag to show all available arguments
SwiftyPoeditor --help
SwiftyPoeditor download --help
```

## How "download" command works
Download command simply tries to export specified localization by its POEditor language key and override the destination file. The destination file will be created if it does not exist.

## How "upload" command works
Firstly SwiftyPoeditor generates local localization terms (keys) based on localization enum (The localization enum described below.). Then, it downloads all available localization terms from the POEditor service. After, it finds differences between local and remote terms (keys). Newly inserted terms will be uploaded and removed terms will be deleted from POEditor only if it is not restricted by input settings.

**Note: upload command currently works only with described below localization enum.**

## Localization enum example

It is not very convenient to use regular strings as localizations throughout the project.
```swift
localizedLabel.text = "my_localized_text_string_key".localized // string constant
```
It is much more convenient when the localization keys are wrapped in some kind of data structure. 

#### The proposed solution is to use enum:

```swift
protocol LocalizationKeyPathProvider {}

extension LocalizationKeyPathProvider {
    var key: String {
        return String(reflecting: self).lowercased().replacingOccurrences(of: "your_module_name.i18n.", with: "")
    }
    
    var localized: String {
        return self.key.localized // regular localization string extension
    }
    
    func localized(withArguments args: CVarArg...) -> String {
        return String(format: self.localized,
                      arguments: args)
    }
}

// MARK: - Keys
enum I18n {
    enum Common: LocalizationKeyPathProvider {
    
        enum Button: LocalizationKeyPathProvider {
            case send, close, ok
        }
        
        enum Placeholder: LocalizationKeyPathProvider {
            case email, password, country
        }
        
        enum Validation: LocalizationKeyPathProvider {
            case emptyField, invalidPassword, invalidEmail
        }
    }
    
    enum Splash: LocalizationKeyPathProvider {
        case appVersion, demo
    }
    
    enum Login: LocalizationKeyPathProvider {
        case title, forgotPassword
    }
}

```

And now you can use this in your code as follows:
```swift
localizedLabel.text = I18n.Splash.appVersion.localized
```

## Xcode project integration

#### Step 1: Create an Aggregate Target

Select your project in the Project Navigator, click the + button at the bottom left of the Targets section. Select Aggregate in Cross-platform tab. Hit Next.

![create aggregate target](/Resources/Integration/1.png?raw=true)

Choose a name for the new target, e.g "DownloadPoeditor".

![choose target name](/Resources/Integration/2.png?raw=true)

#### Step 2: Add a Run Script Build Phase

In the Build Phases section click the + button to add a new Run Script phase.

![add new run script](/Resources/Integration/3.png?raw=true)

In the shell script window enter the SwiftyPoeditor command with all required params. Be sure to include the `--yes` flag.

**Note: `--yes` flag required for Xcode/CI integrations. This flag skips user validation phase of passed arguments and uses default values for optional parameters if they are not specified in passed arguments. Otherwise, the program will be suspended pending data entry or user confirmation.**

![type script command](/Resources/Integration/4.png?raw=true)

#### Step 3: Select & Run

You're ready to roll. You should now see the new scheme in the scheme selector. Select it and hit run.

**Also, you can integrate SwiftyPoeditor with your CI.**

#### Build phase scripts examples:
##### Upload command:
```bash
# check if SwiftyPoeditor available
# and install if not available
FILE=/usr/local/bin/SwiftyPoeditor
if test -f "$FILE"; then
    echo "SwiftyPoeditor installed and can be used"
else 
    echo "SwiftyPoeditor not installed. Will try to install"

    TEMP_PATH=./SwiftyPoeditprTemp

    rm -Rf ${TEMP_PATH}
    git clone https://github.com/oleksandrviturk/SwiftyPoeditor.git ${TEMP_PATH}
    cd ${TEMP_PATH}
    sh ./install.sh
    cd -
    rm -Rf ${TEMP_PATH}
fi
# run SwiftyPoeditor
echo "SwiftyPoeditor start execution"

SwiftyPoeditor upload --path "$PROJECT_DIR/PATH/TO/LocalizationEnum/I18n.swift" --name I18n --token API_TOKEN --id PROJECT_ID --delete-removals false --yes --short-output

echo "SwiftyPoeditor end execution"
```
##### Download command:
```bash
# check if SwiftyPoeditor available
# and install if not available
FILE=/usr/local/bin/SwiftyPoeditor
if test -f "$FILE"; then
    echo "SwiftyPoeditor installed and can be used"
else 
    echo "SwiftyPoeditor not installed. Will try to install"

    TEMP_PATH=./SwiftyPoeditprTemp

    rm -Rf ${TEMP_PATH}
    git clone https://github.com/oleksandrviturk/SwiftyPoeditor.git ${TEMP_PATH}
    cd ${TEMP_PATH}
    sh ./install.sh
    cd -
    rm -Rf ${TEMP_PATH}
fi
# run SwiftyPoeditor
echo "SwiftyPoeditor start execution"

SwiftyPoeditor download -t API_TOKEN -i PROJECT_ID -l en -d "$PROJECT_DIR/PATH/TO/EN/STRINGS/Localizable.strings" -e apple_strings --yes --short-output
SwiftyPoeditor download -t API_TOKEN -i PROJECT_ID -l ANOTHER_LANGUAGE_CODE -d "$PROJECT_DIR/PATH/TO/ANOTHER_LANGUAGE/STRINGS/Localizable.strings" -e apple_strings --yes --short-output

echo "SwiftyPoeditor end execution"
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Authors

* **[Oleksandr Vitruk](https://www.linkedin.com/in/alexvitruk/)**
* **[Artem Kostetsky](https://www.linkedin.com/in/artem-kostetsky-48ba4ab9/)**

## License
This project is licensed under the [MIT](https://choosealicense.com/licenses/mit/) License - see the LICENSE.md file for details

