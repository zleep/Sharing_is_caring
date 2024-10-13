shader_type spatial;
render_mode diffuse_toon, specular_toon, depth_prepass_alpha;

// Written by the fullmetalphysicist, adapted from Aerthas Veras blender shader GGST shader


// import the textures
// base colour texture, needs to be placed in the inspector shader window (right side bar)
uniform sampler2D base_colour : source_color, filter_nearest;


// shadow colour texture
//uniform sampler2D shadow_colour: source_color, filter_nearest;
// if no shadow colour texure use base_colour and multiply
//uniform vec3 shadow_colour = texture(base_colour, UV).rgb * vec3(0.0);
uniform vec4 shading_multiplier : source_color = vec4(.737, .746, .956, .408);

// R, G, B, and Alpha channels:
uniform sampler2D R_tga : source_color, filter_nearest;
uniform sampler2D G_tga : source_color, filter_nearest;
uniform sampler2D B_tga : source_color, filter_nearest;
uniform sampler2D A_tga : source_color, filter_nearest;


// RGB and A channels for finished models where combiend .tga is used
//uniform sampler2D combined_tga : source_color, filter_nearest;

// light_push values
uniform float light_push : hint_range(0., 3.0) = 2.146;
// shadow_push values
uniform float shadow_push : hint_range(0., 1.0) = .501;


// specular size value (how big is the shiny spots)
uniform float specular_size : hint_range (-1.0, 3.0) = .2;
// specular colour ( highlight for non metals)
uniform vec4 specular_colour : source_color = vec4(.631, .284, .278, 1.);
// specular colour mix strength
uniform float specular_mix_strength : hint_range(0., 1.) = 0.35;
//specular observation angle
uniform float specualr_observation_angle :hint_range(0., 1.) = .8;


// metal mix colour
uniform vec4 shiny_colour : source_color;
// metal mix strength
uniform float shiny_strength : hint_range(0., 1.) = .5;
uniform float metal_colour_angle : hint_range(0.,1.) = .7;


// eyeshadow_colour
uniform vec4 eye_shadow_colour : source_color = vec4(.7, .7, .7, .7);



void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	// test base colour
	ALBEDO = texture(base_colour, UV).rgb;
	
	
	// test shading colour
	// ALBEDO = texture(shading_colour, UV).rgb;
	
	// 		shadow shader multiply
	//vec4 base_tex = texture(base_colour, UV);
	//vec3 base_hsv = rgb2hsv(base_tex.rgb);
	//vec3 shdmultiplier_hsv = rgb2hsv(shading_multiplier.rgb);
	//vec3 combined_hsv = base_hsv + shdmultiplier_hsv * .408;
	//vec3 combined_rgb = hsv2rgb(combined_hsv);
	//ALBEDO = combined_rgb;
	
	//ALBEDO = shadow_colour_rbga.rgb;
	
	// test R channel
	//ALBEDO = texture(R_tga, UV).rgb;
	
	// test B channel
	//ALBEDO = texture(B_tga, UV).rgb;
	
	// test G channel
	//ALBEDO = texture(G_tga, UV).rgb;
	
	// test A channel
	//ALBEDO = texture(A_tga, UV).rgb;
	

	
	
	}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	
	// fetch the normals, light vector and viewing vectors
	// LIGHT 	// light vector in view sapce
	// NORMAL 	// surface normals in view space
	// VIEW		// cmera view in view space already normalised
	
	//normalise the 3 vectors
	vec3 light_vec = normalize(LIGHT);
	vec3 normal_vec = normalize(NORMAL);
	VIEW;
	
	
	
	// take the dot of the three vectors
	float dot_normal_camera = dot(normal_vec, VIEW);
	float dot_middle = dot(normalize(VIEW + light_vec), normal_vec);
	float dot_normal_light = dot(normal_vec, light_vec);
	
	
	
	// shadning angle calculations
	float shading_angle = (dot_normal_light + light_push) * .5;
	
	// manipulate G channel
	float ILM_G = texture(G_tga, UV).g * 2.;
	ILM_G -= 1.;
	
	// add the two
	shading_angle += ILM_G;
	
	// light is > shadow is less i.e. light = 1, shadow = 0 
	float lig_sil = step(shadow_push, shading_angle);
	// check the angle = push, if != 0
	float lig_sil_compare = float((shadow_push == shading_angle));
	
	//compare the two and get maximum
	float max_light_shadow = max(lig_sil, lig_sil_compare);
	
	
	// 				shading the model, stick on the light and dark
	
	// lets start by redeclaring the tecture its more convinient
	vec4 base_colour_rgba = texture(base_colour, UV);
	
	
	// shadow texture
	//vec4 shadow_colour_rgba = texture(shadow_colour, UV);
	vec4 shadow_colour_rbga = texture(base_colour, UV) + shading_multiplier;
	
	// so check which state it has and multiply albedo to display correctly
		if(bool(max_light_shadow) == true)
	{
		SPECULAR_LIGHT = ALBEDO;
	} else
	{
		SPECULAR_LIGHT = ALBEDO*(shading_multiplier.rgb);
		// SPECULAR_LIGHT = shadow_colour_rgba.rgb;
	}
	
	
	// now add in the permanent shadows (ambient occlusion)
	
	// re define ILM_G
	ILM_G = texture(G_tga, UV).g;
	
	// check if ILM_G < 0.16, if it is = 1 perms shade, never lit
	bool ILM_G_comp = bool(ILM_G < 0.16);
	
	// use the bool check as a factor
	if (ILM_G_comp == true){
		SPECULAR_LIGHT = ALBEDO*(shading_multiplier.rgb);
		// SPECULAR_LIGHT = shadow_colour_rgba.rgb;
	} 
	
	
	// use G channel to add in permanent light
	// of G > .9 never shade
	ILM_G_comp = bool(ILM_G > 0.9);
	
	// use the bool check as a factor
	if (ILM_G_comp == true){
		SPECULAR_LIGHT = ALBEDO;
	} 
	
	
	// time to do the shiny calulations for non metals (Specular or B_tga)
	
	// clamp specular size
	float specular_size_sub = clamp(specular_size - 1.0, 0., 1.);
	
	// take ILM_B
	float ILM_B = texture(B_tga, UV).b;
	
	// specular shading factor calulation
	bool ILM_B_checked = ILM_B > specular_size_sub;
	
	
	// mix specular_colour 
	vec3 specular_mix_colour = specular_colour.rgb * specular_mix_strength;
	
	//now mix base and specular as a function of ILM_B
	if (ILM_B > .49){
		if (dot_middle > specualr_observation_angle){
			SPECULAR_LIGHT = ALBEDO + ILM_B * specular_mix_colour;
		}
	}
	
	
	// metal shiny channel or R_tga
	
	// get ILM_R data
	float ILM_R = texture(R_tga, UV).r;
	
	// this ones easy we just mix the metal shiny colour with the base texture when the dot of light and normal is > metal_colour_angle
	if (dot_middle > metal_colour_angle){
		SPECULAR_LIGHT += (shiny_strength * shiny_colour.rgb * ILM_R);
	}	
}

