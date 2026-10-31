# Series

Edit freely, then run `py pipeline/build.py series` (also part of a full build) and `publish`.

Each series: a heading `## id | English | French | German | Spanish | signature bird (Latin)`, then any of
`order:`, `family:`, `genus:` (rules matched against the catalog) and `birds:` (Latin names),
comma-separated, and `reward:` (the rarity of the card the player collects on completing it:
uncommon, rare, epic or legendary). A bird belongs to the series if it matches any line. Names
not in the catalog are skipped (listed when the step runs). In the app, a series only shows if at
least 3 of its birds live in the player's region; the badge photo is the signature bird, or the
series' first bird of the region.

A heading without `|` (`## Families`, `## Habitats`, `## Themes`) starts a group: one page in the
app. Game achievements (Legendary hunter, Perfect week, Full set…) are in the app's code, not here.

## Families

## gulls | Gulls | Goélands et mouettes | Möwen | Gaviotas | Larus argentatus
genus: Larus, Chroicocephalus, Ichthyaetus, Hydrocoloeus, Rissa, Xema, Leucophaeus
reward: rare

## owls | Owls | Chouettes et hiboux | Eulen | Búhos y lechuzas | Strix aluco
order: Strigiformes
reward: epic

## woodpeckers | Woodpeckers | Pics | Spechte | Pájaros carpinteros | Dendrocopos major
family: Picidae
reward: rare

## ducks | Ducks & geese | Canards et oies | Enten & Gänse | Patos y gansos | Anas platyrhynchos
family: Anatidae
reward: epic

## raptors | Birds of prey | Rapaces | Greifvögel | Rapaces | Buteo buteo
order: Accipitriformes, Falconiformes
reward: epic

## herons | Herons & egrets | Hérons et aigrettes | Reiher | Garzas | Ardea cinerea
family: Ardeidae
reward: rare

## waders | Waders | Limicoles | Watvögel | Limícolas | Numenius arquata
family: Scolopacidae, Charadriidae, Haematopodidae, Recurvirostridae
reward: epic

## corvids | Crows & jays | Corvidés | Rabenvögel | Córvidos | Garrulus glandarius
family: Corvidae
reward: rare

## tits | Tits | Mésanges | Meisen | Carboneros | Parus major
family: Paridae, Aegithalidae
reward: uncommon

## finches | Finches | Fringilles | Finken | Fringílidos | Fringilla coelebs
family: Fringillidae
reward: rare

## swallows | Swallows & swifts | Hirondelles et martinets | Schwalben & Segler | Golondrinas y vencejos | Hirundo rustica
family: Hirundinidae, Apodidae
reward: uncommon

## thrushes | Thrushes | Grives et merles | Drosseln | Zorzales y mirlos | Turdus philomelos
family: Turdidae
reward: rare

## Habitats

## woods | Deep woods | Forêt profonde | Tiefer Wald | Bosque profundo | Dryocopus martius
birds: Dryocopus martius, Tetrao urogallus, Tetrastes bonasia, Garrulus glandarius,
  Regulus ignicapilla, Phylloscopus sibillatrix, Certhia brachydactyla, Sitta europaea,
  Accipiter gentilis, Dryocopus pileatus, Seiurus aurocapilla, Hylocichla mustelina,
  Bonasa umbellus
reward: rare

## mountains | Mountain peaks | Haute montagne | Hochgebirge | Alta montaña | Tichodroma muraria
birds: Pyrrhocorax graculus, Tichodroma muraria, Prunella collaris, Montifringilla nivalis,
  Lagopus muta, Gypaetus barbatus, Aquila chrysaetos, Anthus spinoletta, Tachymarptis melba,
  Alectoris graeca, Cinclus mexicanus, Nucifraga columbiana, Lagopus leucura,
  Leucosticte tephrocotis
reward: epic

## sand | A walk in the sand | Balade sur la plage | Strandspaziergang | Paseo por la arena | Calidris alba
birds: Calidris alba, Charadrius alexandrinus, Charadrius hiaticula, Haematopus ostralegus,
  Thalasseus sandvicensis, Sternula albifrons, Arenaria interpres, Morus bassanus,
  Galerida cristata, Charadrius melodus, Rynchops niger, Pelecanus occidentalis,
  Tringa semipalmata
reward: rare

## city | City citizens | Citadins | Stadtbewohner | Vecinos de la ciudad | Passer domesticus
birds: Passer domesticus, Columba livia, Apus apus, Phoenicurus ochruros, Sturnus vulgaris,
  Falco peregrinus, Delichon urbicum, Streptopelia decaocto, Coloeus monedula,
  Psittacula krameri, Haemorhous mexicanus, Chaetura pelagica, Quiscalus quiscula
reward: uncommon

## reeds | Reed beds | Roselières | Schilfgürtel | Carrizales | Panurus biarmicus
birds: Acrocephalus scirpaceus, Acrocephalus arundinaceus, Acrocephalus schoenobaenus,
  Panurus biarmicus, Botaurus stellaris, Circus aeruginosus, Rallus aquaticus,
  Emberiza schoeniclus, Locustella luscinioides, Ardea purpurea, Cistothorus palustris,
  Agelaius phoeniceus, Rallus limicola
reward: rare

## fields | Open fields | Plaines et champs | Felder und Wiesen | Campos abiertos | Alauda arvensis
birds: Alauda arvensis, Perdix perdix, Coturnix coturnix, Emberiza calandra, Emberiza citrinella,
  Vanellus vanellus, Falco tinnunculus, Circus pygargus, Tetrax tetrax, Sturnella magna,
  Dolichonyx oryzivorus, Falco sparverius, Charadrius vociferus
reward: rare

## Themes

## black | Birds in black | Oiseaux en noir | Ganz in Schwarz | Aves de negro | Turdus merula
birds: Turdus merula, Corvus corone, Corvus frugilegus, Corvus corax, Coloeus monedula,
  Sturnus vulgaris, Sturnus unicolor, Apus apus, Phoenicurus ochruros, Fulica atra,
  Melanitta nigra, Chlidonias niger, Ciconia nigra, Dryocopus martius, Phalacrocorax carbo,
  Pyrrhocorax pyrrhocorax, Pyrrhocorax graculus, Corvus brachyrhynchos, Quiscalus quiscula,
  Euphagus cyanocephalus, Agelaius phoeniceus, Molothrus ater
reward: uncommon

## garden | My garden's feeder | La mangeoire du jardin | Mein Futterhaus | Mi comedero | Erithacus rubecula
birds: Erithacus rubecula, Turdus merula, Parus major, Cyanistes caeruleus, Fringilla coelebs,
  Passer domesticus, Troglodytes troglodytes, Prunella modularis, Phoenicurus ochruros,
  Chloris chloris, Carduelis carduelis, Sylvia atricapilla, Phylloscopus collybita,
  Sitta europaea, Aegithalos caudatus, Turdus philomelos, Pyrrhula pyrrhula, Serinus serinus,
  Turdus migratorius, Cardinalis cardinalis, Poecile atricapillus, Haemorhous mexicanus,
  Melospiza melodia, Spinus tristis, Sialia sialis, Thryothorus ludovicianus,
  Baeolophus bicolor, Junco hyemalis, Mimus polyglottos
reward: uncommon

## rainbow | Color party | Fête des couleurs | Farbenfest | Fiesta de colores | Alcedo atthis
birds: Alcedo atthis, Merops apiaster, Coracias garrulus, Upupa epops, Oriolus oriolus,
  Carduelis carduelis, Pyrrhula pyrrhula, Luscinia svecica, Tichodroma muraria, Picus viridis,
  Aix galericulata, Phoenicopterus roseus, Cardinalis cardinalis, Passerina cyanea,
  Passerina ciris, Piranga olivacea, Icterus galbula, Setophaga petechia, Cyanocitta cristata,
  Aix sponsa
reward: rare

## leafwarblers | Leaf warblers | Pouillots | Laubsänger | Mosquiteros | Phylloscopus proregulus
birds: Phylloscopus inornatus, Phylloscopus proregulus, Phylloscopus humei, Phylloscopus fuscatus,
  Phylloscopus schwarzi, Phylloscopus borealis, Phylloscopus trochiloides,
  Phylloscopus plumbeitarsus, Phylloscopus ibericus, Phylloscopus bonelli,
  Phylloscopus orientalis, Phylloscopus coronatus, Phylloscopus nitidus,
  Phylloscopus tenellipes, Phylloscopus griseolus, Phylloscopus examinandus,
  Phylloscopus sindianus, Phylloscopus maculipennis
reward: legendary

## white | White knights | Chevaliers blancs | Weiße Ritter | Caballeros blancos | Ardea alba
birds: Ciconia ciconia, Ardea alba, Egretta garzetta, Bubulcus ibis, Platalea leucorodia,
  Pelecanus onocrotalus, Cygnus olor, Cygnus cygnus, Cygnus columbianus, Bubo scandiacus,
  Falco rusticolus, Pagophila eburnea, Larus hyperboreus, Plectrophenax nivalis,
  Anser caerulescens, Lagopus lagopus
reward: epic

## legends | Birders' legends | Légendes des cocheurs | Legenden der Vogelbeobachter | Leyendas de los pajareros | Phylloscopus inornatus
birds: Phylloscopus inornatus, Xema sabini, Tichodroma muraria, Luscinia svecica,
  Coccothraustes coccothraustes, Bubo scandiacus, Tetrax tetrax, Otis tarda,
  Aegolius funereus, Glaucidium passerinum, Bombycilla garrulus, Panurus biarmicus,
  Remiz pendulinus, Gypaetus barbatus, Ficedula parva, Calidris pugnax,
  Strix nebulosa, Setophaga kirtlandii, Grus americana, Gymnogyps californianus,
  Pinicola enucleator, Setophaga cerulea, Picoides arcticus
reward: legendary
