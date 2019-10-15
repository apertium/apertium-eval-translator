cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(apertium-eval-translator
	VERSION 1.2.1
	LANGUAGES NONE
	)

install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/apertium-eval-translator.pl"
	DESTINATION bin
	RENAME "apertium-eval-translator"
	)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/beam-eval-until-stable" _tmp)
string(REPLACE "apertium-eval-translator.pl" "apertium-eval-translator" _tmp "${_tmp}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/beam-eval-until-stable" "${_tmp}")

install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/beam-eval-until-stable"
	DESTINATION bin
	)
