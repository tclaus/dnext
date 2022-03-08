# Init a Language detector wit this minimal and maximal text length to scan
MINIMAL_TEXT_LENGTH = 40
MAXIMAL_TEXT_LENGTH = 780
CLD = CLD3::NNetLanguageIdentifier.new(MINIMAL_TEXT_LENGTH, MAXIMAL_TEXT_LENGTH)
