/// Our labels for the 1.2.6 item JSON, which carries no names of its own.
///
/// In 1.8.7 the page prints `➜ Nível de Ataque +70` and the parser reads the
/// name the game chose. Here there is no such line: the numbers sit raw in
/// `data-item`, in the game server's own column names. So every label below
/// is **ours**, and each one is a claim about what that column measures —
/// a kind of error the 1.8.7 parser cannot make.
///
/// Frequencies measured over 439 items from thirty characters on 01/10/2026.
const atributos126 = <String, String>{
  'damage_high_max': 'Dano máximo', // 12% — a arma
  'damage_high_min': 'Dano mínimo', // 12%
  'magic_damage_high_max': 'Dano mágico máximo',
  'magic_damage_high_min': 'Dano mágico mínimo',
  'attack_speed': 'Velocidade de ataque', // 12%
  'attack_range': 'Alcance', // 12%
  'defense': 'Defesa', // 52%
  'armor': 'Armadura', // 26%
  'hp_enhance': 'HP', // 20%
  'mp_enhance': 'MP', // 16%
  'metal': 'Resistência ao metal', // 41%
  'wood': 'Resistência à madeira', // 44%
  'water': 'Resistência à água', // 45%
  'fire': 'Resistência ao fogo', // 42%
  'earth': 'Resistência à terra', // 38%
};

/// Fields deliberately left out until somebody who plays confirms them.
///
/// `item_flag` (69%) and `item_class` (100%) are read by nothing. Showing a
/// number without knowing what it measures is the same mistake as
/// `Movimento m/seg. +1036831949`, which this repository chose to print as the
/// site prints it rather than invent a meaning for.
const naoTraduzidos126 = {'item_flag', 'item_class'};
