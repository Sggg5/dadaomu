# Original generation provenance — all DRAFT

All artwork was generated with the built-in imagegen tool for this project. No third-party museum photograph or commercial game sprite was supplied. This is an original game-art workflow, not a claim that a depicted fictional object is a real museum accession. AI-generated status is not human art approval.

| Saved original | Request and transformation |
|---|---|
| actors_original.png | Transparent6×6 atlas, four explorer directions and scarab/gunman rows, six idle/stride/attack/hurt/death poses,1933khaki/teal palette. Derived48×64 frames with aspect-preserving nearest reduction. |
| environment_original.png |4×2 original texture atlas: four weathered grey-stone floors, wall, banded wood coffin, warm parquet, brass glass showcase. Floor contrast reduced after actual engine readability inspection; props preserve fine detail. |
| antiques_original.png |4×2 transparent atlas of eight independent fictional silvercoin/jar/Buddha/jadebi/inlaidmirror/sancaihorse/jadependant/guardianfragment archetypes. No museum accession copied or claimed. |
| museum_npcs_before_cutout.png |6×2 original1933museum visitors/guide/appraiser/conservator/curator, idle andstride. |
| museum_npcs_original.png |imagegen edit of the previous image: remove background while preserving sprites. The returned image retainedRGB behind zero alpha; derived sprite alpha threshold128 and nearest resizing remove fringe. |
| furniture_original.png |4×2 transparent original director/construction/appraisal/restoration/research desks, intelligenceboard, ticketcounter, dealerdesk. |

Runtime only loads derived PNGs in the parent directory. This sources directory is excluded from Godot import by.gdignore. Media/license review status remains AI_GENERATED_ORIGINAL_PENDING_REVIEW, not CC0 or expert approval. Missing dedicated Boss and regional-antique art is not silently filled with these images.

Phase12A.1新增原画：player_rework_original.png（4×4身体姿态，侧向行装配纠正）；stone_rework_original.png（低对比石地）。OpenAI built-in imagegen原创生成，2026-10-10，DRAFT_PENDING_USER_REVIEW。派生脚本tools/build_phase12a1_assets.py只作图集裁切、原生尺寸/透明/脚底整理及地面调色与周期边缘处理。没有现实博物馆媒体或外部游戏素材。

## Phase 12A.2 陈设生成

Built-in imagegen，原始源exec-1cc71d36-99b6-4f05-9f15-24b03e0515fe.png复制为tomb_props_original.png。透明输出，六物件单图集，3列2行；normalize工具裁切各格alpha范围、最近邻规范化为128×160，不改变旧素材。全部DRAFT/PENDING_USER_REVIEW。

Prompt: Create ONE production sprite atlas on truly transparent background for original northern Chinese tomb 2D top-down oblique game. Single sheet 3 columns by 2 rows, six clearly separate sprites, generous empty gutters, no labels, no text. Row1 left ancient grey carved STONE COFFIN with tapered lid raised on plinth, middle aged dark WOODEN COFFIN with tapered anthropomorphic shape iron straps and worn lacquer not crate, right low STONE COFFIN BED with stepped platform. Row2 left short octagonal STONE PILLAR with square base and chipped capital, middle BROKEN OFFERING ALTAR with carved offering cup and cracked slab, right GROUP OF TWO BROKEN BURIAL POTTERY JARS. Consistent nearly top-down view with visible south-facing vertical faces, orthographic no isometric diamond, aligned vertical north-south sprites. Sophisticated HD2D pixel game art, visibly deliberate crisp pixel clusters, dark cool desaturated grey olive stone, restrained warm brown wood, subtle carved motifs, worn realistic stone surfaces. Upper left soft highlights, black lower contact shadows. Each sprite fills about 75 percent of its cell, no touching adjacent cells, no floor/background/environment, transparent outside. No actors, enemies, weapons. Original fictional ancient tomb props, no real museum item identity. Atlas illustrative assets only, not screenshot.
