# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

target 'visualrecognitionios' do
    pod 'BMSCore', '~> 2.6'

    # Comment this line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod "SwiftSpinner", '~> 1.6.0'
    pod 'KTCenterFlowLayout', '~> 1.3.1'
    pod 'IBMWatsonVisualRecognitionV3', '~> 1.3.1'

    # Pods for visualrecognitionios

    target 'visualrecognitioniosTests' do
        inherit! :search_paths
        # Pods for testing
    end

    target 'visualrecognitioniosUITests' do
        inherit! :search_paths
        # Pods for testing
    end

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            if ['SwiftCloudant', 'KTCenterFlowLayout'].include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '3.2'
                end
            end
        end
    end
end
