# Makefile pour changer la disposition du clavier

# Cible par défaut
.PHONY: azerty azerty_mac qwerty

# Disposition AZERTY classique (français PC)
azerty:
	setxkbmap -model pc105 -layout fr -variant oss
	@echo "Disposition changée : AZERTY classique (fr)"

# Disposition AZERTY Mac (clavier Apple)
azerty_mac:
	setxkbmap -layout fr -variant mac
	@echo "Disposition changée : AZERTY Mac (fr+oss)"

# Disposition QWERTY US
qwerty:
	setxkbmap -model pc105 -layout us
	@echo "Disposition changée : QWERTY US"

# Vérifie la disposition actuelle
status:
	setxkbmap -query
