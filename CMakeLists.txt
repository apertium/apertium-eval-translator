cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
project(apertium-eval-translator
	VERSION 1.2.2
	LANGUAGES NONE
	)

install(PROGRAMS "apertium-eval-translator.pl"
	DESTINATION bin
	RENAME "apertium-eval-translator"
	)

install(PROGRAMS "apertium-eval-translator-line.pl"
	DESTINATION bin
	RENAME "apertium-eval-translator-line"
	)

file(READ "beam-eval-until-stable" _tmp)
string(REPLACE "apertium-eval-translator.pl" "apertium-eval-translator" _tmp "${_tmp}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/beam-eval-until-stable" "${_tmp}")

install(PROGRAMS
	"apertium-eval"
	"${CMAKE_CURRENT_BINARY_DIR}/beam-eval-until-stable"
	DESTINATION bin
	)
