cmake_minimum_required(VERSION 3.15)
project(88emuplayer VERSION ${CMAKE_PROJECT_VERSION})
set(HARDWARE_SKIN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/assets)
set(HARDWARE_ASSETS
	assets/emu88Player.rml
	assets/emu88Player.rcss
	assets/emu88PlayerSettings.rml
	assets/emu88PlayerSettingsWindow.rml
	assets/emu88PlayerSettings.rcss
	assets/emu88PartEditor.rml
	assets/emu88PartEditor.rcss
	assets/part_editor_mixer.svg
	assets/part_editor_menu.svg
	assets/part_editor_grip.svg
	assets/about.png
	${HARDWARE_SKIN_DIR}/sc88_panel.png
	${HARDWARE_SKIN_DIR}/sc88vl_panel.png
	${HARDWARE_SKIN_DIR}/sc88pro_panel.png
	${HARDWARE_SKIN_DIR}/sc8850_panel.png
	${HARDWARE_SKIN_DIR}/sc880_panel.png
	${HARDWARE_SKIN_DIR}/sc880_overlay.png
	${HARDWARE_SKIN_DIR}/sc55_panel.png
	${HARDWARE_SKIN_DIR}/sc55mk2_panel.png
	${HARDWARE_SKIN_DIR}/sc8820_panel.png
	${HARDWARE_SKIN_DIR}/cm32p_panel.png
	${HARDWARE_SKIN_DIR}/cm32l_panel.png
	${HARDWARE_SKIN_DIR}/cm64_panel.png
	${HARDWARE_SKIN_DIR}/mt32_panel.png
	${HARDWARE_SKIN_DIR}/sc88exp_panel.png
	${HARDWARE_SKIN_DIR}/sc55pc_panel.png
	${HARDWARE_SKIN_DIR}/mv30_panel.png
	${HARDWARE_SKIN_DIR}/mv30_assets.png
	${HARDWARE_SKIN_DIR}/sc8850_assets.png
	${HARDWARE_SKIN_DIR}/button_all.svg
	${HARDWARE_SKIN_DIR}/button_left.svg
	${HARDWARE_SKIN_DIR}/button_right.svg
	${HARDWARE_SKIN_DIR}/button_round.svg
	${HARDWARE_SKIN_DIR}/button_led_on.svg
	${HARDWARE_SKIN_DIR}/button_part_left.svg
	${HARDWARE_SKIN_DIR}/button_part_right.svg
	${HARDWARE_SKIN_DIR}/button_plain.svg
	${HARDWARE_SKIN_DIR}/sc880_key.svg
	${HARDWARE_SKIN_DIR}/sc880_key_lit.svg
	${HARDWARE_SKIN_DIR}/preview.svg
	${HARDWARE_SKIN_DIR}/player_play.svg
	${HARDWARE_SKIN_DIR}/player_pause.svg
	${HARDWARE_SKIN_DIR}/player_stop.svg
	${HARDWARE_SKIN_DIR}/player_play_dark.svg
	${HARDWARE_SKIN_DIR}/player_pause_dark.svg
	${HARDWARE_SKIN_DIR}/player_stop_dark.svg
	${HARDWARE_SKIN_DIR}/selector_led_off.svg
	${HARDWARE_SKIN_DIR}/selector_led_on.svg
	${HARDWARE_SKIN_DIR}/efx_led_off.svg
	${HARDWARE_SKIN_DIR}/efx_led_on.svg
	${HARDWARE_SKIN_DIR}/efx_led_green.svg
	${HARDWARE_SKIN_DIR}/efx_led_amber.svg
	${HARDWARE_SKIN_DIR}/cm_led_on.png
	${HARDWARE_SKIN_DIR}/knob.png
	${HARDWARE_SKIN_DIR}/cm_volume_knob.png
	${HARDWARE_SKIN_DIR}/value_knob.png
)
# The formats to build, from the same USE_* switches source/cmake/juce.cmake derives for the
# synths: the Standalone is the full player application, the plugin formats put the player
# into a host, which then owns the audio device and hands the MIDI in. VST2 needs the SDK
# (or the FST headers findvst2.cmake falls back to), exactly as it does for the synths.
set(playerFormats "")
if(USE_Standalone)
	list(APPEND playerFormats Standalone)
endif()
if(USE_VST3)
	list(APPEND playerFormats VST3)
endif()
if(USE_VST2 AND JUCE_GLOBAL_VST2_SDK_PATH)
	list(APPEND playerFormats VST)
endif()
if(NOT playerFormats)
	return()
endif()

juce_add_binary_data(88emuplayer_BinaryData SOURCES ${HARDWARE_ASSETS})
juce_add_plugin(88emuplayer
	# The 512px application icon supplies both ICNS and Windows ICO sizes.
	ICON_BIG "${CMAKE_CURRENT_SOURCE_DIR}/assets/icon.png"
	COMPANY_NAME "The Usual Suspects"
	COMPANY_WEBSITE "https://dsp56300.wordpress.com"
	IS_SYNTH TRUE
	NEEDS_MIDI_INPUT TRUE
	NEEDS_MIDI_OUTPUT TRUE
	IS_MIDI_EFFECT FALSE
	EDITOR_WANTS_KEYBOARD_FOCUS TRUE
	COPY_PLUGIN_AFTER_BUILD FALSE
	PLUGIN_MANUFACTURER_CODE TusP
	PLUGIN_CODE TscH
	FORMATS ${playerFormats}
	PRODUCT_NAME "88emuPlayer"
	PRODUCTS_FOLDER "${TUS_BIN_DIR}/plugins/$<CONFIG>"
	VST3_AUTO_MANIFEST ${TUS_CAN_RUN_BUILT_BINARIES}
	BUNDLE_ID "com.theusualsuspects.SC88Hardware"
)
target_sources(88emuplayer PRIVATE
	Emu88Processor.cpp Emu88Processor.h
	app/Emu88LaunchOptions.cpp app/Emu88LaunchOptions.h
	app/Emu88Playlist.cpp app/Emu88Playlist.h
	ui/Emu88Editor.cpp ui/Emu88Editor.h
	ui/Emu88EditorPlaylist.cpp
	ui/Emu88EditorSettings.cpp
	ui/Emu88EditorAudioMidi.cpp
	ui/Emu88EditorPanel.cpp
	ui/Emu88EditorSkin.cpp
	ui/Emu88EditorWindows.cpp
	ui/Emu88PartEditor.cpp ui/Emu88PartEditor.h
	ui/Emu88EditorPlaylist.h
	ui/Emu88EditorLcd.h
	ui/Emu88EditorWindows.h
	ui/Emu88EditorBindings.h
	ui/panel.cpp ui/panel.hpp
)
removeJuceDependencies(88emuplayer)
target_link_libraries(88emuplayer PRIVATE
	88emuplayer_BinaryData
	88lib
	hardwareLib
	jucePlayerLib
	juceMidiPorts
	juceRmlUi
	juceUiLib
	jucePluginData
	juce_plugin_modules
)
target_compile_definitions(88emuplayer PUBLIC JUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1)
set_property(TARGET 88emuplayer PROPERTY FOLDER "Ronaldo/88emu")
set_property(TARGET 88emuplayer_BinaryData PROPERTY FOLDER "Ronaldo/88emu")
# Build the generated version header before compiling the player.
if(TARGET jucePluginLib)
	add_dependencies(88emuplayer jucePluginLib)
endif()
if(TARGET PluginFormat_Standalone)
	add_dependencies(PluginFormat_Standalone 88emuplayer_Standalone)
endif()
# Each built format gets its own install rule and CPack component, mirroring what
# createJucePlugin() does for the synths. ${playerComponents} collects them so the license,
# readme and changelog below ship with every one.
set(playerProductName "88emuPlayer")
set(playerComponents "")

# The standalone. No macOS setup script: the README explains how to allow the quarantined
# app and CLI in System Settings.
if(TARGET 88emuplayer_Standalone)
	list(APPEND playerComponents ${playerProductName}-Standalone)
	if(APPLE)
		install(TARGETS 88emuplayer_Standalone DESTINATION . COMPONENT ${playerProductName}-Standalone)
	elseif(MSVC)
		install(TARGETS 88emuplayer_Standalone RUNTIME DESTINATION . COMPONENT ${playerProductName}-Standalone)
	else()
		install(TARGETS 88emuplayer_Standalone RUNTIME DESTINATION bin/ COMPONENT ${playerProductName}-Standalone)
	endif()
endif()

# The VST3: a bundle directory, installed as createJucePlugin() installs the synths'.
if(TARGET 88emuplayer_VST3)
	list(APPEND playerComponents ${playerProductName}-VST3)
	add_dependencies(PluginFormat_VST3 88emuplayer_VST3)
	if(APPLE)
		install(TARGETS 88emuplayer_VST3 DESTINATION . COMPONENT ${playerProductName}-VST3)
		installMacSetupScript(. ${playerProductName}-VST3)
	else()
		get_target_property(vst3OutputFolder 88emuplayer_VST3 ARCHIVE_OUTPUT_DIRECTORY)
		if(UNIX)
			set(vst3Dest lib/vst3)
			set(vst3Pattern "*.so")
		else()
			set(vst3Dest .)
			set(vst3Pattern "*.vst3")
		endif()
		install(DIRECTORY ${vst3OutputFolder}/${playerProductName}.vst3 DESTINATION ${vst3Dest}
			COMPONENT ${playerProductName}-VST3 FILES_MATCHING PATTERN ${vst3Pattern} PATTERN "*.json")
	endif()
	addPluginTest(88emuplayer_VST3)
endif()

# The VST2, built against the FST headers unless a real SDK is present.
if(TARGET 88emuplayer_VST)
	list(APPEND playerComponents ${playerProductName}-VST2)
	add_dependencies(PluginFormat_VST2 88emuplayer_VST)
	if(UNIX AND NOT APPLE)
		# JUCE leaves the default "lib" prefix on the Linux VST2, see createJucePlugin() (BUG-10214)
		set_target_properties(88emuplayer_VST PROPERTIES PREFIX "")
	endif()
	if(MSVC OR APPLE)
		install(TARGETS 88emuplayer_VST DESTINATION . COMPONENT ${playerProductName}-VST2)
		if(APPLE)
			installMacSetupScript(. ${playerProductName}-VST2)
		endif()
	else()
		install(TARGETS 88emuplayer_VST LIBRARY DESTINATION lib/vst/ COMPONENT ${playerProductName}-VST2)
	endif()
	addPluginTest(88emuplayer_VST)
endif()
set_target_properties(88emuplayer PROPERTIES TUS_PRODUCT_NAME "${playerProductName}")
tus_exportTarget(88emuplayer)
# The generated changelog may be absent when this product has no entries.
tus_registerChangelog(88emuplayer)
foreach(playerComponent IN LISTS playerComponents)
	install(FILES "${CMAKE_SOURCE_DIR}/LICENSE.md"
		DESTINATION .
		COMPONENT ${playerComponent})
	install(FILES "${CMAKE_SOURCE_DIR}/doc/88emu_readme.md"
		DESTINATION .
		RENAME README.md
		COMPONENT ${playerComponent})
	# The generated changelog may be absent when this product has no entries.
	install(FILES "${CMAKE_SOURCE_DIR}/doc/changelog_split/changelog_${playerProductName}.txt"
		DESTINATION .
		COMPONENT ${playerComponent}
		OPTIONAL)
endforeach()
# Keep JUCE's wrapper, but own startup configuration before it opens devices. The definition is
# read by the Standalone wrapper only, so it stays on the shared code whatever formats build.
if(TARGET 88emuplayer_Standalone)
	target_sources(88emuplayer_Standalone PRIVATE app/Emu88Standalone.cpp)
endif()
target_compile_definitions(88emuplayer PUBLIC JUCE_USE_CUSTOM_PLUGIN_STANDALONE_APP=1)
# The CLI's --video mode renders the player's own UI, so it links the plugin's shared code (the
# processor, the editor and the skin assets) rather than growing a second copy of the front panel.
# It is an application like the standalone and ships in its component, so it builds with it.
if(USE_Standalone)
	add_executable(88EmuCli app/Emu88Cli.cpp app/Emu88LaunchOptions.cpp app/Emu88VideoRender.cpp)
	target_link_libraries(88EmuCli PRIVATE 88emuplayer 88emuplayer_BinaryData 88lib jucePlayerLib juceRmlUi
		juceUiLib jucePluginData juce_plugin_modules)
	target_compile_definitions(88EmuCli PRIVATE JUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1)
	set_target_properties(88EmuCli PROPERTIES FOLDER "Ronaldo/88emu" RUNTIME_OUTPUT_DIRECTORY "${TUS_BIN_DIR}/plugins/$<CONFIG>")
	if(WIN32)
		target_link_libraries(88EmuCli PRIVATE shell32)
	endif()
	if(TARGET PluginFormat_Standalone)
		add_dependencies(PluginFormat_Standalone 88EmuCli)
	endif()
	if(APPLE OR WIN32)
		install(TARGETS 88EmuCli RUNTIME DESTINATION . COMPONENT ${playerProductName}-Standalone)
	else()
		install(TARGETS 88EmuCli RUNTIME DESTINATION bin COMPONENT ${playerProductName}-Standalone)
	endif()
endif()
if(BUILD_TESTING)
	add_executable(88emuLaunchOptions_test tests/Emu88LaunchOptions_test.cpp app/Emu88LaunchOptions.cpp app/Emu88Playlist.cpp)
	target_link_libraries(88emuLaunchOptions_test PRIVATE 88lib jucePlayerLib)
	add_test(NAME 88emuLaunchOptions COMMAND 88emuLaunchOptions_test)
	set_property(TARGET 88emuLaunchOptions_test PROPERTY FOLDER "Ronaldo/tests")
endif()

# Numeric argument validation must retain NaN/Inf checks in Release.
foreach(target IN ITEMS 88emuplayer 88EmuCli 88emuLaunchOptions_test)
	if(TARGET ${target})
		if(MSVC)
			target_compile_options(${target} PRIVATE /fp:precise)
		else()
			target_compile_options(${target} PRIVATE -fno-finite-math-only)
		endif()
	endif()
endforeach()
