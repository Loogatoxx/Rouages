shader_type spatial;
// Plateau de l'établi en bois procédural (playtest 1, PT-56 : « la texture de la table est moche »).
// Planches parallèles à X (largeur `largeur_planche`), teinte propre à chaque planche, joints sombres, fil du bois étiré
// le long de la planche et petits nœuds, vernis satiné. Calculé dans l'espace du monde : aucune texture étirée.

uniform vec3 miel : source_color = vec3(0.70, 0.46, 0.25);
uniform vec3 noyer : source_color = vec3(0.50, 0.30, 0.15);
uniform vec3 clair : source_color = vec3(0.80, 0.58, 0.36);
uniform float largeur_planche = 1.6;
uniform float longueur_planche = 9.0;

varying vec3 monde;

float hachage(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hachage(i), hachage(i + vec2(1.0, 0.0)), u.x),
			mix(hachage(i + vec2(0.0, 1.0)), hachage(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float somme = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		somme += amplitude * bruit(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return somme;
}

void vertex() {
	monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = monde.xz;
	float rangee = floor(p.y / largeur_planche);
	// Les planches d'une rangée sont décalées pour que les joints de bout ne s'alignent pas.
	float decalage = hachage(vec2(rangee, 3.1)) * longueur_planche;
	float colonne = floor((p.x + decalage) / longueur_planche);
	vec2 planche = vec2(colonne, rangee);
	float teinte = hachage(planche);
	vec3 base = mix(miel, mix(noyer, clair, teinte), 0.2 + 0.15 * hachage(planche + 7.0));
	// Fil du bois : bruit très étiré le long de la planche, ondulé.
	vec2 local = vec2(p.x + decalage, p.y) + planche * 13.0;
	float fil = fbm(vec2(local.x * 0.35, local.y * 9.0 + fbm(local * 0.6) * 2.0));
	float veines = smoothstep(0.35, 0.75, fil);
	vec3 couleur = mix(base, base * 0.68, veines * 0.7);
	// Nœuds occasionnels.
	vec2 cellule = floor(local * vec2(0.5, 1.2));
	vec2 centre = cellule + vec2(hachage(cellule), hachage(cellule + 1.7));
	float noeud = 1.0 - smoothstep(0.0, 0.18, length((local * vec2(0.5, 1.2) - centre) * vec2(1.0, 2.2)));
	couleur = mix(couleur, noyer * 0.8, noeud * step(0.86, hachage(cellule + 4.2)) * 0.8);
	// Joints entre planches (côtés et bouts).
	float v = fract(p.y / largeur_planche);
	float u = fract((p.x + decalage) / longueur_planche);
	float joint = max(1.0 - smoothstep(0.0, 0.012, min(v, 1.0 - v)),
			1.0 - smoothstep(0.0, 0.0025, min(u, 1.0 - u)));
	couleur = mix(couleur, noyer * 0.45, joint * 0.85);
	ALBEDO = couleur;
	ROUGHNESS = mix(0.42, 0.62, veines) + joint * 0.2;
	SPECULAR = 0.45;
}
