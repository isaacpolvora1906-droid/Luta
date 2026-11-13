class_name Roster
extends RefCounted
## Elenco: 26 estados, cada um com seu animal, estilo, arma e cenário na capital.
## O Distrito Federal fica de fora por enquanto.

const GRID_COLUMNS := 6
const GRID_ROWS := 5

const CHARACTERS: Array[Dictionary] = [
	{"uf": "AC", "animal": "Gavião-Real", "style": "Muay Thai", "weapon": "Zarabatana", "stage": "Rio Branco (Floresta Nebulosa)"},
	{"uf": "AL", "animal": "Caranguejo", "style": "Brawler", "weapon": "Duas Foices Curtas", "stage": "Maceió (Praia do Francês à noite)"},
	{"uf": "AP", "animal": "Tucano", "style": "Acrobático", "weapon": "Lança Tribal", "stage": "Macapá (Marco Zero do Equador)"},
	{"uf": "AM", "animal": "Onça-Pintada", "style": "Grappler (Agarrões)", "weapon": "Borduna (Clava)", "stage": "Manaus (Teatro Amazonas Chuvoso)"},
	{"uf": "BA", "animal": "Tartaruga-Marinha", "style": "Capoeira", "weapon": "Berimbau-Bastão", "stage": "Salvador (Elevador Lacerda)"},
	{"uf": "CE", "animal": "Carcará", "style": "Rushdown", "weapon": "Peixeira Serrilhada", "stage": "Fortaleza (Mercado Central)"},
	{"uf": "ES", "animal": "Beija-Flor", "style": "Velocista", "weapon": "Rapieira", "stage": "Vitória (Convento da Penha)"},
	{"uf": "GO", "animal": "Lobo-Guará", "style": "Zoning", "weapon": "Chicote de Couro", "stage": "Goiânia (Praça Cívica)"},
	{"uf": "MA", "animal": "Guará", "style": "Místico", "weapon": "Cajado de Madeira", "stage": "São Luís (Centro Histórico)"},
	{"uf": "MT", "animal": "Jacaré-do-Pantanal", "style": "Tank (Armadura)", "weapon": "Mangual", "stage": "Cuiabá (Pantanal em chamas)"},
	{"uf": "MS", "animal": "Capivara", "style": "Defensivo", "weapon": "Martelo Gigante", "stage": "Campo Grande (Parque das Nações)"},
	{"uf": "MG", "animal": "Tamanduá-Bandeira", "style": "Street Brawler", "weapon": "Picareta de Minas", "stage": "Belo Horizonte (Praça da Liberdade)"},
	{"uf": "PA", "animal": "Búfalo-de-Marajó", "style": "Bruiser Pesado", "weapon": "Machado Duplo", "stage": "Belém (Mercado Ver-o-Peso)"},
	{"uf": "PB", "animal": "Bode", "style": "Kickboxer", "weapon": "Nunchaku", "stage": "João Pessoa (Farol do Cabo Branco)"},
	{"uf": "PR", "animal": "Gralha-Azul", "style": "Combate à distância", "weapon": "Arco e Flecha", "stage": "Curitiba (Jardim Botânico)"},
	{"uf": "PE", "animal": "Leão do Norte", "style": "Dança das Lâminas", "weapon": "Sombrinha com Lâminas", "stage": "Recife (Marco Zero / Frevo)"},
	{"uf": "PI", "animal": "Tatu-Bola", "style": "Roll Attacks", "weapon": "Escudo com Espinhos", "stage": "Teresina (Ponte Estaiada)"},
	{"uf": "RJ", "animal": "Mico-Leão-Dourado", "style": "Malandro", "weapon": "Taco de Beisebol com Pregos", "stage": "Rio de Janeiro (Pão de Açúcar / Bondinhos)"},
	{"uf": "RN", "animal": "Ema", "style": "Chutes Rápidos", "weapon": "Bumerangue Gigante", "stage": "Natal (Dunas de Genipabu)"},
	{"uf": "RS", "animal": "Cavalo Crioulo", "style": "Tae Kwon Do", "weapon": "Boleadeiras e Facão", "stage": "Porto Alegre (Usina do Gasômetro)"},
	{"uf": "RO", "animal": "Boto", "style": "Esguio", "weapon": "Tridente", "stage": "Porto Velho (Estrada de Ferro Madeira-Mamoré)"},
	{"uf": "RR", "animal": "Iguana", "style": "Tático", "weapon": "Zarabatana de Dardos", "stage": "Boa Vista (Praça das Águas)"},
	{"uf": "SC", "animal": "Pinguim", "style": "Criomante", "weapon": "Machado de Gelo", "stage": "Florianópolis (Ponte Hercílio Luz)"},
	{"uf": "SP", "animal": "Cachorro-Caramelo", "style": "MMA", "weapon": "Corrente de Aço", "stage": "São Paulo (Avenida Paulista com trânsito)"},
	{"uf": "SE", "animal": "Arara", "style": "Aéreo", "weapon": "Chakram", "stage": "Aracaju (Orla de Atalaia)"},
	{"uf": "TO", "animal": "Sucuri", "style": "Grappler (Constrição)", "weapon": "Chicote de Correntes", "stage": "Palmas (Praça dos Girassóis)"},
]


static func find(uf: String) -> Dictionary:
	for character in CHARACTERS:
		if character.uf == uf:
			return character
	return {}
