# Series

Edit freely, then run `py pipeline/build.py series` (also part of a full build) and `publish`.

Each series: a heading `## id | English | French | German | Spanish | signature bird (Latin)`, then any of
`order:`, `family:`, `genus:` (rules matched against the catalog) and `birds:` (Latin names),
comma-separated. A bird belongs to the series if it matches any line. Names not in the
catalog are skipped (listed when the step runs). In the app, a series only shows if at least
3 of its birds live in the player's region; the badge photo is the signature bird, or the
series' first bird of the region.

Game achievements (Legendary hunter, Perfect week, Full set) are in the app's code, not here.

## Families

## gulls | Gulls | Goélands et mouettes | Möwen | Gaviotas | Larus argentatus
genus: Larus, Chroicocephalus, Ichthyaetus, Hydrocoloeus, Rissa, Xema, Leucophaeus

## owls | Owls | Chouettes et hiboux | Eulen | Búhos y lechuzas | Strix aluco
order: Strigiformes

## woodpeckers | Woodpeckers | Pics | Spechte | Pájaros carpinteros | Dendrocopos major
family: Picidae

## ducks | Ducks & geese | Canards et oies | Enten & Gänse | Patos y gansos | Anas platyrhynchos
family: Anatidae

## raptors | Birds of prey | Rapaces | Greifvögel | Rapaces | Buteo buteo
order: Accipitriformes, Falconiformes

## herons | Herons & egrets | Hérons et aigrettes | Reiher | Garzas | Ardea cinerea
family: Ardeidae

## waders | Waders | Limicoles | Watvögel | Limícolas | Numenius arquata
family: Scolopacidae, Charadriidae, Haematopodidae, Recurvirostridae

## corvids | Crows & jays | Corvidés | Rabenvögel | Córvidos | Garrulus glandarius
family: Corvidae

## tits | Tits | Mésanges | Meisen | Carboneros | Parus major
family: Paridae, Aegithalidae

## finches | Finches | Fringilles | Finken | Fringílidos | Fringilla coelebs
family: Fringillidae

## swallows | Swallows & swifts | Hirondelles et martinets | Schwalben & Segler | Golondrinas y vencejos | Hirundo rustica
family: Hirundinidae, Apodidae

## thrushes | Thrushes | Grives et merles | Drosseln | Zorzales y mirlos | Turdus philomelos
family: Turdidae

## Themes

## black | Birds in black | Oiseaux en noir | Ganz in Schwarz | Aves de negro | Turdus merula
birds: Turdus merula, Corvus corone, Corvus frugilegus, Corvus corax, Coloeus monedula,
  Sturnus vulgaris, Sturnus unicolor, Apus apus, Phoenicurus ochruros, Fulica atra,
  Melanitta nigra, Chlidonias niger, Ciconia nigra, Dryocopus martius, Phalacrocorax carbo,
  Pyrrhocorax pyrrhocorax, Pyrrhocorax graculus, Corvus brachyrhynchos, Quiscalus quiscula,
  Euphagus cyanocephalus, Agelaius phoeniceus, Molothrus ater

## garden | Garden songbirds | Passereaux du jardin | Gartensänger | Pájaros del jardín | Erithacus rubecula
birds: Erithacus rubecula, Turdus merula, Parus major, Cyanistes caeruleus, Fringilla coelebs,
  Passer domesticus, Troglodytes troglodytes, Prunella modularis, Phoenicurus ochruros,
  Chloris chloris, Carduelis carduelis, Sylvia atricapilla, Phylloscopus collybita,
  Sitta europaea, Aegithalos caudatus, Turdus philomelos, Pyrrhula pyrrhula, Serinus serinus,
  Turdus migratorius, Cardinalis cardinalis, Poecile atricapillus, Haemorhous mexicanus,
  Melospiza melodia, Spinus tristis, Sialia sialis, Thryothorus ludovicianus,
  Baeolophus bicolor, Junco hyemalis, Mimus polyglottos

## rainbow | Rainbow birds | Oiseaux arc-en-ciel | Regenbogenvögel | Aves arcoíris | Alcedo atthis
birds: Alcedo atthis, Merops apiaster, Coracias garrulus, Upupa epops, Oriolus oriolus,
  Carduelis carduelis, Pyrrhula pyrrhula, Luscinia svecica, Tichodroma muraria, Picus viridis,
  Aix galericulata, Phoenicopterus roseus, Cardinalis cardinalis, Passerina cyanea,
  Passerina ciris, Piranga olivacea, Icterus galbula, Setophaga petechia, Cyanocitta cristata,
  Aix sponsa

## night | Night singers | Chanteurs de la nuit | Nachtsänger | Cantores nocturnos | Luscinia megarhynchos
birds: Luscinia megarhynchos, Caprimulgus europaeus, Strix aluco, Bubo bubo, Otus scops,
  Athene noctua, Tyto alba, Locustella naevia, Acrocephalus palustris, Burhinus oedicnemus,
  Crex crex, Antrostomus vociferus, Megascops asio, Bubo virginianus, Strix varia,
  Mimus polyglottos

## eagles | Eagles | Aigles | Adler | Águilas | Aquila chrysaetos
birds: Aquila chrysaetos, Haliaeetus albicilla, Haliaeetus leucocephalus, Aquila heliaca,
  Aquila adalberti, Aquila clanga, Aquila pomarina, Hieraaetus pennatus, Aquila fasciata,
  Circaetus gallicus, Pandion haliaetus

## Birders' legends

## legends | Birders' legends | Légendes des cocheurs | Legenden der Vogelbeobachter | Leyendas de los pajareros | Phylloscopus inornatus
birds: Phylloscopus inornatus, Xema sabini, Tichodroma muraria, Luscinia svecica, Upupa epops,
  Merops apiaster, Coccothraustes coccothraustes, Bubo scandiacus, Tetrax tetrax, Otis tarda,
  Aegolius funereus, Glaucidium passerinum, Bombycilla garrulus, Panurus biarmicus,
  Remiz pendulinus, Gypaetus barbatus, Ficedula parva, Calidris pugnax,
  Strix nebulosa, Setophaga kirtlandii, Grus americana, Gymnogyps californianus,
  Pinicola enucleator, Setophaga cerulea, Picoides arcticus
