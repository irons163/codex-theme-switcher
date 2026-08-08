enum L10nCatalogCJK {
    static let simplifiedChinese: [String: String] = catalog(\.simplifiedChinese)
    static let japanese: [String: String] = catalog(\.japanese)
    static let korean: [String: String] = catalog(\.korean)

    private struct Entry {
        let key: String
        let simplifiedChinese: String
        let japanese: String
        let korean: String

        init(
            _ key: String,
            _ simplifiedChinese: String,
            _ japanese: String,
            _ korean: String
        ) {
            self.key = key
            self.simplifiedChinese = simplifiedChinese
            self.japanese = japanese
            self.korean = korean
        }
    }

    private static func catalog(
        _ translation: KeyPath<Entry, String>
    ) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: entries.map {
                ($0.key, $0[keyPath: translation])
            }
        )
    }

    private static let entries: [Entry] = [
        .init(" Copy", " 副本", " のコピー", " 복사본"),
        .init(
            "Voice avatar mode",
            "Voice 角色模式",
            "Voiceアバターモード",
            "Voice 아바타 모드"
        ),
        .init(
            "The three modes are independent. Switching modes does not remove flat-image or Live2D assets.",
            "三种模式彼此独立；切换模式不会删除平面图或 Live2D 素材。",
            "3つのモードは独立しています。モードを切り替えても2D画像やLive2Dアセットは削除されません。",
            "세 가지 모드는 서로 독립적입니다. 모드를 전환해도 평면 이미지나 Live2D 에셋은 삭제되지 않습니다."
        ),
        .init(
            "Avatar mode",
            "角色模式",
            "アバターモード",
            "아바타 모드"
        ),
        .init(
            "Avatar area size",
            "角色区域大小",
            "アバター領域のサイズ",
            "아바타 영역 크기"
        ),
        .init(
            "Expands ChatGPT's native Voice window with the avatar. Increase it when a large or full-body Live2D model is clipped.",
            "会连同 ChatGPT 原生 Voice 窗口一起放大；大型或全身 Live2D 被裁切时可调高。",
            "アバターと一緒にChatGPT標準のVoiceウィンドウも拡大します。大きなモデルや全身のLive2Dが切れる場合は値を上げてください。",
            "아바타와 함께 ChatGPT 기본 Voice 창도 확대됩니다. 크거나 전신인 Live2D 모델이 잘리면 값을 높이세요."
        ),
        .init(
            "Native orb",
            "原生圆球",
            "標準オーブ",
            "기본 구체"
        ),
        .init(
            "Flat image / mouth frames",
            "平面图／嘴型图",
            "2D画像／口形フレーム",
            "평면 이미지 / 입 모양 프레임"
        ),
        .init(
            "Import a .model3.json first. The native orb remains visible until the model is ready.",
            "请先导入 .model3.json；模型准备完成前会保留原生圆球。",
            "先に.model3.jsonを読み込んでください。モデルの準備が整うまでは標準オーブが表示されます。",
            "먼저 .model3.json을 가져오세요. 모델이 준비될 때까지 기본 구체가 표시됩니다."
        ),
        .init(
            "No Live2D model imported",
            "尚未导入 Live2D 模型",
            "Live2Dモデルが読み込まれていません",
            "가져온 Live2D 모델이 없습니다"
        ),
        .init(
            "Live2D uses WebGL. Apply the theme and open a Voice conversation to inspect the real animation.",
            "Live2D 使用 WebGL；请套用主题并打开 Voice 对话查看实际动画。",
            "Live2DはWebGLを使用します。テーマを適用してVoice会話を開き、実際のアニメーションを確認してください。",
            "Live2D는 WebGL을 사용합니다. 테마를 적용하고 Voice 대화를 열어 실제 애니메이션을 확인하세요."
        ),
        .init(
            "Import a Cubism .model3.json and its referenced resources. Existing flat-image settings stay in the theme.",
            "导入 Cubism .model3.json 及其引用的资源。现有平面图设置仍会保留在主题中。",
            "Cubismの.model3.jsonと参照リソースを読み込みます。既存の2D画像設定はテーマ内に保持されます。",
            "Cubism .model3.json과 참조 리소스를 가져옵니다. 기존 평면 이미지 설정은 테마에 유지됩니다."
        ),
        .init(
            "No model selected",
            "尚未选择模型",
            "モデルが選択されていません",
            "선택한 모델이 없습니다"
        ),
        .init(
            "{0} files · {1}",
            "{0} 个文件 · {1}",
            "{0}ファイル · {1}",
            "파일 {0}개 · {1}"
        ),
        .init(
            "Import model",
            "导入模型",
            "モデルを読み込む",
            "모델 가져오기"
        ),
        .init(
            "Replace model",
            "更换模型",
            "モデルを置き換える",
            "모델 교체"
        ),
        .init(
            "Model scale",
            "模型缩放",
            "モデルの拡大率",
            "모델 크기"
        ),
        .init(
            "Idle motion strength",
            "待机动作强度",
            "待機モーションの強さ",
            "대기 모션 강도"
        ),
        .init(
            "The importer is responsible for model and character rights. Confirm the Cubism SDK publication license before distributing the app.",
            "导入者须自行负责模型与角色权利；公开发布应用前也请确认 Cubism SDK 的发布许可。",
            "モデルとキャラクターの権利は読み込む側の責任です。アプリを配布する前にCubism SDKの公開ライセンスも確認してください。",
            "모델과 캐릭터 권리는 가져오는 사용자가 책임집니다. 앱을 배포하기 전에 Cubism SDK 공개 라이선스도 확인하세요."
        ),
        .init(
            "Choose Live2D model3.json",
            "选择 Live2D model3.json",
            "Live2D model3.jsonを選択",
            "Live2D model3.json 선택"
        ),
        .init(
            "Choose the .model3.json inside an exported Cubism folder. Referenced model, texture, physics, and motion files will be embedded with the theme.",
            "请选择 Cubism 导出文件夹内的 .model3.json；引用的模型、贴图、物理与动作文件会一并嵌入主题。",
            "Cubismの書き出しフォルダ内にある.model3.jsonを選択してください。参照されるモデル、テクスチャ、物理演算、モーションの各ファイルがテーマに埋め込まれます。",
            "Cubism 내보내기 폴더의 .model3.json을 선택하세요. 참조된 모델, 텍스처, 물리 및 모션 파일이 테마에 함께 포함됩니다."
        ),
        .init(
            "Import Live2D model",
            "导入 Live2D 模型",
            "Live2Dモデルを読み込む",
            "Live2D 모델 가져오기"
        ),
        .init(
            "Imported the Live2D model with {0} files.",
            "已导入 Live2D 模型及 {0} 个文件。",
            "Live2Dモデルと{0}個のファイルを読み込みました。",
            "Live2D 모델과 파일 {0}개를 가져왔습니다."
        ),
        .init(
            "Change Voice avatar mode",
            "更改 Voice 角色模式",
            "Voiceアバターモードを変更",
            "Voice 아바타 모드 변경"
        ),
        .init(
            "Remove Live2D model",
            "移除 Live2D 模型",
            "Live2Dモデルを削除",
            "Live2D 모델 제거"
        ),
        .init(
            "“{0}” is not a valid Live2D .model3.json file.",
            "“{0}”不是有效的 Live2D .model3.json 文件。",
            "「{0}」は有効なLive2D .model3.jsonファイルではありません。",
            "“{0}”은(는) 올바른 Live2D .model3.json 파일이 아닙니다."
        ),
        .init(
            "The Live2D model is missing “{0}”.",
            "Live2D 模型缺少“{0}”。",
            "Live2Dモデルに「{0}」がありません。",
            "Live2D 모델에 “{0}” 파일이 없습니다."
        ),
        .init(
            "Live2D resource path “{0}” escapes the model folder.",
            "Live2D 资源路径“{0}”超出模型文件夹。",
            "Live2Dリソースのパス「{0}」がモデルフォルダの外を参照しています。",
            "Live2D 리소스 경로 “{0}”이(가) 모델 폴더를 벗어납니다."
        ),
        .init(
            "Enable idle motion",
            "启用待机动作",
            "待機モーションを有効にする",
            "대기 모션 사용"
        ),
        .init(
            "Parameter mapping",
            "参数对应",
            "パラメータ対応",
            "파라미터 매핑"
        ),
        .init(
            "Map mouth and head motion here when the model uses custom parameter IDs.",
            "若模型使用自定义参数 ID，可在此对应嘴型与头部动作。",
            "モデルが独自のパラメータIDを使う場合は、ここで口と頭の動きを対応付けます。",
            "모델이 사용자 지정 파라미터 ID를 사용하면 여기에서 입과 머리 동작을 매핑하세요."
        ),
        .init(
            "Mouth open",
            "嘴巴张合",
            "口の開閉",
            "입 벌림"
        ),
        .init(
            "Head angle X",
            "头部水平",
            "頭部の水平角度",
            "머리 수평 각도"
        ),
        .init(
            "Head angle Y",
            "头部垂直",
            "頭部の垂直角度",
            "머리 수직 각도"
        ),
        .init(
            "Head angle Z",
            "头部倾斜",
            "頭部の傾き",
            "머리 기울기"
        ),
        .init(
            "Body angle X",
            "身体水平",
            "身体の水平角度",
            "몸 수평 각도"
        ),
        .init(
            "Live2D requires internet access when its renderer starts so it can load the official Cubism Core.",
            "Live2D renderer 启动时需要网络，以加载官方 Cubism Core。",
            "Live2Dレンダラーの起動時に公式Cubism Coreを読み込むため、インターネット接続が必要です。",
            "Live2D 렌더러가 시작될 때 공식 Cubism Core를 불러오려면 인터넷 연결이 필요합니다."
        ),
        .init(
            "Remove",
            "移除",
            "削除",
            "제거"
        ),
        .init(
            "Horizontal position",
            "水平位置",
            "水平位置",
            "수평 위치"
        ),
        .init(
            "Vertical position",
            "垂直位置",
            "垂直位置",
            "수직 위치"
        ),
        .init(
            "16 MB per asset; 32 MB total assets; 48 MB per template",
            "每个素材上限 16 MB；素材总量 32 MB；每个模板上限 48 MB",
            "アセットごとに16 MB、合計32 MB、テンプレートごとに48 MB",
            "에셋당 16MB, 전체 에셋 32MB, 템플릿당 48MB"
        ),
        .init("2XL radius", "超大圆角", "2XL角丸", "2XL 모서리 반경"),
        .init("ACTIVE", "使用中", "使用中", "사용 중"),
        .init("Accent", "强调色", "アクセント", "강조 색상"),
        .init("Active selection", "选中项目", "アクティブ選択", "활성 선택"),
        .init("Add CSS rule", "添加 CSS 规则", "CSSルールを追加", "CSS 규칙 추가"),
        .init(
            "Add a background or font and it will travel with the export.",
            "添加背景或字体后，导出时会一并打包。",
            "背景やフォントを追加すると、書き出し時に一緒に含まれます。",
            "배경이나 글꼴을 추가하면 내보낼 때 함께 포함됩니다."
        ),
        .init(
            "Add any --color-token-*, --vscode-*, or custom CSS variable",
            "添加任意 --color-token-*、--vscode-* 或自定义 CSS 变量",
            "任意の --color-token-*、--vscode-*、カスタムCSS変数を追加",
            "--color-token-*, --vscode-* 또는 사용자 지정 CSS 변수를 추가하세요"
        ),
        .init("Add asset", "添加素材", "アセットを追加", "에셋 추가"),
        .init("Add component override", "添加组件覆盖", "コンポーネント上書きを追加", "컴포넌트 재정의 추가"),
        .init("Add conditional layer", "添加条件图层", "条件レイヤーを追加", "조건부 레이어 추가"),
        .init("Add declaration", "添加声明", "宣言を追加", "선언 추가"),
        .init("Add image or font", "添加背景、图像或字体", "画像またはフォントを追加", "이미지 또는 글꼴 추가"),
        .init("Add token", "添加 token", "トークンを追加", "토큰 추가"),
        .init("Advanced Tokens", "高级 Token", "高度なトークン", "고급 토큰"),
        .init("All modes", "所有模式", "すべてのモード", "모든 모드"),
        .init("Always applied", "始终应用", "常に適用", "항상 적용"),
        .init("App background", "应用背景", "アプリ背景", "앱 배경"),
        .init("Appearance", "外观", "外観", "모양"),
        .init(
            "Apply earlier (lower cascade priority)",
            "提前应用（降低层叠优先级）",
            "先に適用（カスケード優先度を下げる）",
            "먼저 적용(캐스케이드 우선순위 낮음)"
        ),
        .init(
            "Apply later (higher cascade priority)",
            "稍后应用（提高层叠优先级）",
            "後で適用（カスケード優先度を上げる）",
            "나중에 적용(캐스케이드 우선순위 높음)"
        ),
        .init(
            "Apply or export it as-is, or make a copy to customize it.",
            "可直接应用或导出，也可创建副本后自由定制。",
            "そのまま適用・書き出すか、コピーを作成してカスタマイズできます。",
            "그대로 적용하거나 내보내거나, 복사본을 만들어 사용자 지정할 수 있습니다."
        ),
        .init(
            "Arbitrary selector rules are the second escape hatch. Selectors may change across Codex updates, so document compatible versions when sharing.",
            "任意 selector 规则是第二层扩展手段。Codex 更新后 selector 可能变化，因此分享时请注明兼容版本。",
            "任意のselectorルールは、もう一つの拡張手段です。Codexの更新でselectorが変わる可能性があるため、共有時は対応バージョンを明記してください。",
            "임의 selector 규칙은 두 번째 확장 수단입니다. Codex 업데이트로 selector가 바뀔 수 있으므로 공유할 때 호환 버전을 명시하세요."
        ),
        .init("Attached · No theme applied", "已连接 · 尚未应用主题", "接続済み・テーマ未適用", "연결됨 · 적용된 테마 없음"),
        .init("Author", "作者", "作成者", "작성자"),
        .init("BUILT-IN", "内置", "組み込み", "기본 제공"),
        .init("Backdrop blur", "背景模糊", "背景ぼかし", "배경 흐림"),
        .init("Background & focal point", "背景图与焦点", "背景とフォーカルポイント", "배경 및 초점"),
        .init("Background base color", "背景底色", "背景ベースカラー", "배경 기본 색상"),
        .init("Base type scale", "基准字号", "基本文字スケール", "기본 글자 크기"),
        .init("Basic motion duration", "基本动画时长", "基本モーション時間", "기본 모션 시간"),
        .init("Blend mode", "混合模式", "描画モード", "혼합 모드"),
        .init("Border", "边框", "ボーダー", "테두리"),
        .init("Border / glow", "边框／光晕", "ボーダー／グロー", "테두리 / 글로우"),
        .init("Border opacity", "边框不透明度", "ボーダーの不透明度", "테두리 불투명도"),
        .init("Border width", "边框宽度", "ボーダー幅", "테두리 두께"),
        .init("Brightness", "亮度", "明るさ", "밝기"),
        .init("Button background", "按钮背景", "ボタン背景", "버튼 배경"),
        .init("Button icon", "按钮图标", "ボタンアイコン", "버튼 아이콘"),
        .init("Cards / menus", "卡片／菜单", "カード／メニュー", "카드 / 메뉴"),
        .init("Center content panel", "中央内容面板", "中央コンテンツパネル", "중앙 콘텐츠 패널"),
        .init(
            "Changing mode resets to 1.00×; use Image zoom for further adjustment.",
            "切换模式会重置为 1.00×；之后可用“图像缩放”继续调整。",
            "モードを切り替えると1.00倍に戻ります。さらに調整するには「画像ズーム」を使用してください。",
            "모드를 변경하면 1.00배로 초기화됩니다. 추가 조정은 ‘이미지 확대/축소’를 사용하세요."
        ),
        .init("Chat font size", "对话字号", "チャット文字サイズ", "채팅 글자 크기"),
        .init(
            "Choose Launch + Attach Codex first. The first attachment may restart Codex.",
            "请先选择“启动并连接 Codex”。首次连接可能会重新启动 Codex。",
            "先に「Codexを起動して接続」を選択してください。初回接続時はCodexが再起動する場合があります。",
            "먼저 ‘Codex 실행 및 연결’을 선택하세요. 처음 연결할 때 Codex가 다시 시작될 수 있습니다."
        ),
        .init(
            "Choose dark background",
            "选择深色模式背景",
            "ダーク背景を選択",
            "다크 배경 선택"
        ),
        .init("Choose image", "选择图像", "画像を選択", "이미지 선택"),
        .init(
            "Choose light background",
            "选择浅色模式背景",
            "ライト背景を選択",
            "라이트 배경 선택"
        ),
        .init(
            "Choose or create a theme from the library.",
            "请从主题库中选择或创建主题。",
            "ライブラリからテーマを選択するか作成してください。",
            "라이브러리에서 테마를 선택하거나 만드세요."
        ),
        .init("Clear", "清除", "クリア", "지우기"),
        .init("Clear canvas", "极简透明", "クリアキャンバス", "투명 캔버스"),
        .init("Code block", "代码块", "コードブロック", "코드 블록"),
        .init("Code blocks", "代码块", "コードブロック", "코드 블록"),
        .init("Code font", "代码字体", "コードフォント", "코드 글꼴"),
        .init("Code font size", "代码字号", "コード文字サイズ", "코드 글자 크기"),
        .init(
            "Codex attached. Choose a theme, then click Apply.",
            "已连接 Codex。选择主题后点击“应用”。",
            "Codexに接続しました。テーマを選び、「適用」をクリックしてください。",
            "Codex에 연결되었습니다. 테마를 선택한 다음 ‘적용’을 클릭하세요."
        ),
        .init("Codex is not attached", "Codex 尚未连接", "Codexは未接続です", "Codex가 연결되지 않음"),
        .init("Codex is running, not attached", "Codex 正在运行，但尚未连接", "Codexは実行中ですが未接続です", "Codex 실행 중, 연결되지 않음"),
        .init("Color system", "色彩系统", "カラーシステム", "색상 시스템"),
        .init(
            "Complete ANSI base palette; add bright variants under advanced tokens",
            "完整的 ANSI 基础调色板；可在高级 Token 中添加亮色变体",
            "ANSI基本パレット一式。明色バリエーションは高度なトークンで追加できます",
            "전체 ANSI 기본 팔레트. 밝은 변형은 고급 토큰에서 추가할 수 있습니다"
        ),
        .init("Composer / project picker", "Composer／项目选择器", "Composer／プロジェクト選択", "Composer / 프로젝트 선택기"),
        .init("Composer primary button", "Composer 主要按钮", "Composerのメインボタン", "Composer 주요 버튼"),
        .init("Composer radius", "Composer 圆角", "Composerの角丸", "Composer 모서리 반경"),
        .init("Composer tray background", "Composer 托盘背景", "Composerトレイの背景", "Composer 트레이 배경"),
        .init("Condition", "条件", "条件", "조건"),
        .init("Contrast", "对比度", "コントラスト", "대비"),
        .init(
            "Create full-window imagery, independent light/dark treatments, focal cropping, overlays, and per-region glass. Images and settings travel inside the .codextheme.",
            "创建全窗口背景、独立的明暗处理、焦点裁切、遮罩和分区玻璃效果。图像与设置都会包含在 .codextheme 中。",
            "全画面画像、ライト／ダーク別の調整、フォーカルクロップ、オーバーレイ、領域別のガラス効果を作成できます。画像と設定は.codextheme内に保持されます。",
            "전체 창 이미지, 라이트/다크별 처리, 초점 자르기, 오버레이, 영역별 유리 효과를 만들 수 있습니다. 이미지와 설정은 .codextheme에 함께 저장됩니다."
        ),
        .init("Custom rule", "自定义规则", "カスタムルール", "사용자 지정 규칙"),
        .init("Dark", "深色", "ダーク", "다크"),
        .init("Darken bottom", "底部加深", "下を暗くする", "아래쪽 어둡게"),
        .init("Darken left", "左侧加深", "左を暗くする", "왼쪽 어둡게"),
        .init("Darken right", "右侧加深", "右を暗くする", "오른쪽 어둡게"),
        .init("Darken top", "顶部加深", "上を暗くする", "위쪽 어둡게"),
        .init("Delete", "删除", "削除", "삭제"),
        .init("Delete this theme", "删除此主题", "このテーマを削除", "이 테마 삭제"),
        .init("Description", "说明", "説明", "설명"),
        .init("Diff added", "Diff 新增", "Diff追加", "Diff 추가"),
        .init("Diff removed", "Diff 删除", "Diff削除", "Diff 삭제"),
        .init(
            "Directional scrims protect navigation text; vignette darkens the edges.",
            "方向渐变可保护导航文字；暗角会压暗边缘。",
            "方向付きスクリムはナビゲーション文字を保護し、ビネットは縁を暗くします。",
            "방향성 스크림은 탐색 텍스트를 보호하고 비네팅은 가장자리를 어둡게 합니다."
        ),
        .init("Dropdown", "下拉菜单", "ドロップダウン", "드롭다운"),
        .init(
            "Each appearance has independent brightness, contrast, saturation, and blur.",
            "每种外观都有独立的亮度、对比度、饱和度和模糊设置。",
            "各外観には、明るさ、コントラスト、彩度、ぼかしを個別に設定できます。",
            "각 모양에는 밝기, 대비, 채도, 흐림을 독립적으로 설정할 수 있습니다."
        ),
        .init("Edit theme", "编辑主题", "テーマを編集", "테마 편집"),
        .init("Editable copy created", "已创建可编辑副本", "編集可能なコピーを作成しました", "편집 가능한 복사본을 만들었습니다"),
        .init("Editing", "编辑版本", "編集中", "편집 중"),
        .init("Editor", "编辑器", "エディタ", "편집기"),
        .init("Effects & Motion", "效果与动画", "エフェクトとモーション", "효과 및 모션"),
        .init("Embedded Assets", "嵌入素材", "埋め込みアセット", "포함된 에셋"),
        .init("Enable center content panel", "启用中央内容面板", "中央コンテンツパネルを有効化", "중앙 콘텐츠 패널 활성화"),
        .init("Enable image skin", "启用图像皮肤", "画像スキンを有効化", "이미지 스킨 활성화"),
        .init("Enabled", "启用", "有効", "활성화"),
        .init("Error / delete", "错误／删除", "エラー／削除", "오류 / 삭제"),
        .init("Examples", "示例", "例", "예시"),
        .init("Existing assets", "现有素材", "既存のアセット", "기존 에셋"),
        .init(
            "Families, scale, line height, and tracking",
            "字体族、字号、行高与字距",
            "フォントファミリー、スケール、行間、字間",
            "글꼴 모음, 크기, 줄 높이 및 자간"
        ),
        .init("Fill", "填满", "塗りつぶし", "채우기"),
        .init("Fill opacity", "填充不透明度", "塗りの不透明度", "채우기 불투명도"),
        .init(
            "Fill the window and crop edges; focal point controls the crop.",
            "填满窗口并裁切边缘；焦点控制裁切位置。",
            "ウインドウ全体を埋めて端を切り抜きます。フォーカルポイントで切り抜き位置を調整します。",
            "창을 채우고 가장자리를 자릅니다. 초점으로 자르기 위치를 조절합니다."
        ),
        .init("Fill · Crop to Fill", "填满 · 裁切以填满", "塗りつぶし・切り抜いて全体表示", "채우기 · 채우도록 자르기"),
        .init(
            "Final CSS with maximum freedom. For share safety, @import and http(s)/file URLs are rejected; embedded asset macros remain available.",
            "最终 CSS 提供最大自由度。为确保分享安全，将拒绝 @import 和 http(s)/file URL；仍可使用嵌入素材宏。",
            "最大限の自由度を持つ最終CSSです。共有時の安全性のため、@importおよびhttp(s)/file URLは拒否されますが、埋め込みアセットマクロは利用できます。",
            "최대 자유도를 제공하는 최종 CSS입니다. 안전한 공유를 위해 @import 및 http(s)/file URL은 차단되며 포함된 에셋 매크로는 사용할 수 있습니다."
        ),
        .init("Fit", "完整显示", "全体表示", "맞춤"),
        .init("Fit Height", "适应高度", "高さに合わせる", "높이에 맞춤"),
        .init("Fit Width", "适应宽度", "幅に合わせる", "너비에 맞춤"),
        .init("Fit · Show Whole Image", "适应 · 显示完整图像", "全体表示・画像全体を表示", "맞춤 · 전체 이미지 표시"),
        .init(
            "Fit, fill, focal point, and overlays use only the main content area; the sidebar keeps its own base color and glass.",
            "适应、填满、焦点和遮罩仅作用于主内容区；侧边栏保留自己的底色与玻璃效果。",
            "全体表示、塗りつぶし、フォーカルポイント、オーバーレイはメインコンテンツ領域のみに適用され、サイドバーは独自のベースカラーとガラス効果を保ちます。",
            "맞춤, 채우기, 초점 및 오버레이는 기본 콘텐츠 영역에만 적용되며 사이드바는 자체 기본 색상과 유리 효과를 유지합니다."
        ),
        .init("Focus ring", "焦点框", "フォーカスリング", "포커스 링"),
        .init("Foundation", "基础色", "基本色", "기본 색상"),
        .init(
            "Foundation colors compile to stable Codex tokens. Advanced colors target individual surfaces. Fields accept HEX, Display-P3, rgba, gradients, and color-mix.",
            "基础色会编译为稳定的 Codex token；高级颜色可针对特定界面。字段支持 HEX、Display-P3、rgba、渐变和 color-mix。",
            "基本色は安定したCodexトークンにコンパイルされます。高度な色は個別のサーフェスを対象にします。各フィールドではHEX、Display-P3、rgba、グラデーション、color-mixを使用できます。",
            "기본 색상은 안정적인 Codex 토큰으로 컴파일됩니다. 고급 색상은 개별 표면에 적용됩니다. 필드에는 HEX, Display-P3, rgba, 그라데이션 및 color-mix를 사용할 수 있습니다."
        ),
        .init("Geometry & Density", "几何与密度", "形状と密度", "형태 및 밀도"),
        .init(
            "Give the text its own fill, border, spacing, blur, and shadow.",
            "为文字单独设置底色、边框、间距、模糊和阴影。",
            "文字専用の塗り、ボーダー、余白、ぼかし、影を設定します。",
            "텍스트에 별도의 채우기, 테두리, 간격, 흐림 및 그림자를 설정합니다."
        ),
        .init("Glass material", "玻璃材质", "ガラス素材", "유리 재질"),
        .init("Glass saturation", "玻璃饱和度", "ガラスの彩度", "유리 채도"),
        .init("Glass targets", "玻璃应用区域", "ガラスの適用先", "유리 적용 대상"),
        .init("Global overlay", "全局遮罩", "全体オーバーレイ", "전체 오버레이"),
        .init("Global radius", "全局圆角", "全体の角丸", "전체 모서리 반경"),
        .init("Global tracking", "全局字距", "全体の字間", "전체 자간"),
        .init("Gothic gold", "哥特金影", "ゴシックゴールド", "고딕 골드"),
        .init("Has unsaved changes", "有未保存的更改", "未保存の変更があります", "저장되지 않은 변경 사항 있음"),
        .init("Home cards", "首页卡片", "ホームカード", "홈 카드"),
        .init("Horizontal focal point", "水平焦点", "水平フォーカルポイント", "가로 초점"),
        .init("Horizontal padding", "水平内边距", "水平パディング", "가로 안쪽 여백"),
        .init("Horizontal tile origin", "水平平铺起点", "水平タイル原点", "가로 타일 원점"),
        .init(
            "Hover, selection, focus, links, and changes",
            "悬停、选中、焦点、链接和更改标记",
            "ホバー、選択、フォーカス、リンク、変更",
            "호버, 선택, 포커스, 링크 및 변경 사항"
        ),
        .init(
            "Ignore aspect ratio and stretch the image to the window.",
            "忽略宽高比，将图像拉伸至整个窗口。",
            "アスペクト比を無視して、画像をウインドウ全体に引き伸ばします。",
            "가로세로 비율을 무시하고 이미지를 창 전체로 늘립니다."
        ),
        .init("Image blur", "图像模糊", "画像のぼかし", "이미지 흐림"),
        .init("Image opacity", "图像不透明度", "画像の不透明度", "이미지 불투명도"),
        .init("Image sizing", "图像尺寸", "画像サイズ", "이미지 크기"),
        .init("Image treatment", "图像调整", "画像調整", "이미지 조정"),
        .init("Image zoom", "图像缩放", "画像ズーム", "이미지 확대/축소"),
        .init(
            "Images, textures, GIFs, and fonts are base64-embedded in one .codextheme file. Reference them with theme-asset(\"UUID\").",
            "背景图、纹理、GIF 和字体会以 base64 嵌入单个 .codextheme 文件。请使用 theme-asset(\"UUID\") 引用。",
            "画像、テクスチャ、GIF、フォントはbase64形式で1つの.codexthemeファイルに埋め込まれます。theme-asset(\"UUID\")で参照してください。",
            "이미지, 텍스처, GIF 및 글꼴은 하나의 .codextheme 파일에 base64로 포함됩니다. theme-asset(\"UUID\")로 참조하세요."
        ),
        .init(
            "Imports validate schema, CSS safety, size, and ID collisions, and never auto-apply.",
            "导入时会验证 schema、CSS 安全性、容量与 ID 冲突，且绝不会自动应用。",
            "読み込み時にスキーマ、CSSの安全性、サイズ、IDの重複を検証し、自動適用は行いません。",
            "가져올 때 스키마, CSS 안전성, 크기 및 ID 충돌을 검증하며 자동으로 적용하지 않습니다."
        ),
        .init("Input", "输入框", "入力", "입력"),
        .init("Interaction & diff", "交互与 Diff", "操作とDiff", "상호작용 및 Diff"),
        .init("Interface zoom", "界面缩放", "インターフェイスの拡大率", "인터페이스 확대/축소"),
        .init("Keep wallpaper out of sidebar", "壁纸不覆盖侧边栏", "壁紙をサイドバーから除外", "배경화면을 사이드바에서 제외"),
        .init("Large blur", "大型模糊", "大きなぼかし", "큰 흐림"),
        .init("Large radius", "大型组件圆角", "大きな角丸", "큰 모서리 반경"),
        .init("Large shadow", "大型阴影", "大きな影", "큰 그림자"),
        .init("Layer name", "图层名称", "レイヤー名", "레이어 이름"),
        .init("License", "许可证", "ライセンス", "라이선스"),
        .init("Light", "浅色", "ライト", "라이트"),
        .init("Link", "链接", "リンク", "링크"),
        .init("List hover", "列表悬停", "リストのホバー", "목록 호버"),
        .init("Live preview", "实时预览", "ライブプレビュー", "실시간 미리보기"),
        .init(
            "Live simulation of Codex surfaces, conversation, code, and composer.",
            "实时模拟 Codex 的界面、对话、代码和 Composer。",
            "Codexのサーフェス、会話、コード、Composerをリアルタイムでシミュレーションします。",
            "Codex 표면, 대화, 코드 및 Composer를 실시간으로 시뮬레이션합니다."
        ),
        .init("MENU BAR STUDIO", "菜单栏工作室", "メニューバースタジオ", "메뉴 막대 스튜디오"),
        .init("Main content", "主内容", "メインコンテンツ", "기본 콘텐츠"),
        .init("Markdown font size", "Markdown 字号", "Markdown文字サイズ", "Markdown 글자 크기"),
        .init("Markdown line height", "Markdown 行高", "Markdown行間", "Markdown 줄 높이"),
        .init(
            "Match the window height and preserve aspect ratio.",
            "匹配窗口高度并保持宽高比。",
            "アスペクト比を維持しながらウインドウの高さに合わせます。",
            "가로세로 비율을 유지하면서 창 높이에 맞춥니다."
        ),
        .init(
            "Match the window width and preserve aspect ratio.",
            "匹配窗口宽度并保持宽高比。",
            "アスペクト比を維持しながらウインドウの幅に合わせます。",
            "가로세로 비율을 유지하면서 창 너비에 맞춥니다."
        ),
        .init("Maximum width", "最大宽度", "最大幅", "최대 너비"),
        .init("Menu", "菜单", "メニュー", "메뉴"),
        .init("Menus / popovers", "菜单／弹出窗口", "メニュー／ポップオーバー", "메뉴 / 팝오버"),
        .init(
            "Metadata travels with exports for attribution, versioning, and compatibility notes.",
            "完整 metadata 会随模板导出，便于作者署名、版本管理和兼容性说明。",
            "作成者表記、バージョン管理、互換性メモのため、メタデータも一緒に書き出されます。",
            "작성자 표시, 버전 관리 및 호환성 메모를 위해 메타데이터도 함께 내보냅니다."
        ),
        .init("Name", "名称", "名前", "이름"),
        .init("New conditional layer", "新建条件图层", "新規条件レイヤー", "새 조건부 레이어"),
        .init("New theme created", "已创建新主题", "新しいテーマを作成しました", "새 테마를 만들었습니다"),
        .init("No embedded assets", "尚未添加素材", "埋め込みアセットはありません", "포함된 에셋 없음"),
        .init("No image selected", "尚未选择图像", "画像が選択されていません", "선택한 이미지 없음"),
        .init("No theme selected", "尚未选择主题", "テーマが選択されていません", "선택한 테마 없음"),
        .init(
            "No theme will be applied automatically. Choose one and click Apply after attaching. Codex may restart if CDP is not enabled.",
            "不会自动应用主题。连接后请选择主题并点击“应用”。如果未启用 CDP，Codex 可能会重新启动。",
            "テーマは自動適用されません。接続後にテーマを選び、「適用」をクリックしてください。CDPが有効でない場合、Codexが再起動することがあります。",
            "테마는 자동으로 적용되지 않습니다. 연결 후 테마를 선택하고 ‘적용’을 클릭하세요. CDP가 활성화되지 않은 경우 Codex가 다시 시작될 수 있습니다."
        ),
        .init("None", "无", "なし", "없음"),
        .init("Nothing to redo", "没有可重做的操作", "やり直せる操作はありません", "다시 실행할 작업 없음"),
        .init("Nothing to undo", "没有可撤销的操作", "取り消せる操作はありません", "실행 취소할 작업 없음"),
        .init(
            "One file contains the theme, CSS, and every asset",
            "一个文件包含主题、CSS 和所有素材",
            "1つのファイルにテーマ、CSS、すべてのアセットを収録",
            "하나의 파일에 테마, CSS 및 모든 에셋 포함"
        ),
        .init(
            "Only the material background becomes translucent; child text keeps full opacity.",
            "只有材质背景变为半透明；内部文字仍保持完全不透明。",
            "半透明になるのは素材の背景のみで、内部の文字は完全な不透明度を保ちます。",
            "재질 배경만 반투명해지고 내부 텍스트는 완전한 불투명도를 유지합니다."
        ),
        .init("Opacity", "不透明度", "不透明度", "불투명도"),
        .init("Original", "原始大小", "元のサイズ", "원본 크기"),
        .init("Overlay & legibility", "遮罩与可读性", "オーバーレイと視認性", "오버레이 및 가독성"),
        .init("Overlay opacity", "遮罩不透明度", "オーバーレイの不透明度", "오버레이 불투명도"),
        .init("Panel border", "面板边框", "パネルのボーダー", "패널 테두리"),
        .init("Panel fill", "面板填充", "パネルの塗り", "패널 채우기"),
        .init("Panel radius", "面板圆角", "パネルの角丸", "패널 모서리 반경"),
        .init("Per-region glass color", "分区玻璃颜色", "領域別ガラスカラー", "영역별 유리 색상"),
        .init(
            "Preserve aspect ratio and fill the window; overflow is cropped.",
            "保持宽高比并填满窗口；超出部分将被裁切。",
            "アスペクト比を維持してウインドウ全体を埋め、はみ出した部分を切り抜きます。",
            "가로세로 비율을 유지하고 창을 채우며 넘치는 부분은 잘립니다."
        ),
        .init("Preview surface", "预览画面", "プレビュー画面", "미리보기 화면"),
        .init("Primary text", "主要文字", "メインテキスト", "기본 텍스트"),
        .init("Image focal point", "图片焦点", "画像の焦点", "이미지 초점"),
        .init("Quick focal point", "快速设置焦点", "クイックフォーカルポイント", "빠른 초점"),
        .init("Quick styles", "快速样式", "クイックスタイル", "빠른 스타일"),
        .init(
            "Radius, spacing, density, and content width",
            "圆角、间距、密度和内容宽度",
            "角丸、間隔、密度、コンテンツ幅",
            "모서리 반경, 간격, 밀도 및 콘텐츠 너비"
        ),
        .init("Readability scrim", "可读性渐变", "視認性スクリム", "가독성 스크림"),
        .init("Redo", "重做", "やり直す", "다시 실행"),
        .init("Relaxed motion duration", "舒缓动画时长", "ゆったりしたモーション時間", "느린 모션 시간"),
        .init("Remove skin", "移除皮肤", "スキンを削除", "스킨 제거"),
        .init(
            "Repeat the image; zoom controls tile size.",
            "重复平铺图像；缩放控制图块大小。",
            "画像を繰り返し配置し、ズームでタイルサイズを調整します。",
            "이미지를 반복 배치하며 확대/축소로 타일 크기를 조절합니다."
        ),
        .init(
            "Replace the UUID with the value shown above",
            "请将 UUID 替换为上方显示的值",
            "UUIDを上に表示された値に置き換えてください",
            "UUID를 위에 표시된 값으로 바꾸세요"
        ),
        .init("Restored the original Codex style", "已恢复 Codex 原始样式", "Codexの元のスタイルに戻しました", "Codex 기본 스타일을 복원했습니다"),
        .init("Row horizontal padding", "行水平内边距", "行の水平パディング", "행 가로 안쪽 여백"),
        .init("Row vertical padding", "行垂直内边距", "行の垂直パディング", "행 세로 안쪽 여백"),
        .init("Rule name", "规则名称", "ルール名", "규칙 이름"),
        .init("Runtime unavailable", "Runtime 不可用", "Runtimeを利用できません", "Runtime을 사용할 수 없음"),
        .init("Saturation", "饱和度", "彩度", "채도"),
        .init("Scrim strength", "渐变强度", "スクリムの強さ", "스크림 강도"),
        .init("Scrollbar", "滚动条", "スクロールバー", "스크롤 막대"),
        .init("Search themes", "搜索主题", "テーマを検索", "테마 검색"),
        .init("Secondary background", "次要背景", "サブ背景", "보조 배경"),
        .init("Secondary text", "次要文字", "サブテキスト", "보조 텍스트"),
        .init(
            "Selectors are aligned with the current Codex 26 DOM.",
            "Selector 已适配当前 Codex 26 DOM。",
            "selectorは現在のCodex 26 DOMに合わせています。",
            "selector는 현재 Codex 26 DOM에 맞춰져 있습니다."
        ),
        .init("Shadow blur", "阴影模糊", "影のぼかし", "그림자 흐림"),
        .init("Shadow color", "阴影颜色", "影の色", "그림자 색상"),
        .init("Shadow offset X", "阴影水平偏移", "影のXオフセット", "그림자 X 오프셋"),
        .init("Shadow offset Y", "阴影垂直偏移", "影のYオフセット", "그림자 Y 오프셋"),
        .init("Shadow opacity", "阴影不透明度", "影の不透明度", "그림자 불투명도"),
        .init("Share template", "分享模板", "テンプレートを共有", "템플릿 공유"),
        .init(
            "Shared by the enabled Codex regions.",
            "由已启用的 Codex 区域共用。",
            "有効なCodex領域で共有されます。",
            "활성화된 Codex 영역에서 공유됩니다."
        ),
        .init(
            "Show the whole image with its aspect ratio; empty space uses the base color.",
            "保持宽高比并显示完整图像；空白区域使用底色。",
            "アスペクト比を維持して画像全体を表示し、余白にはベースカラーを使用します。",
            "가로세로 비율을 유지하여 전체 이미지를 표시하고 빈 공간에는 기본 색상을 사용합니다."
        ),
        .init(
            "Show the whole image; empty space uses the base color.",
            "显示完整图像；空白区域使用底色。",
            "画像全体を表示し、余白にはベースカラーを使用します。",
            "전체 이미지를 표시하고 빈 공간에는 기본 색상을 사용합니다."
        ),
        .init("Sidebar", "侧边栏", "サイドバー", "사이드바"),
        .init(
            "Sidebar, inputs, menus, code, and terminal",
            "侧边栏、输入框、菜单、代码和 Terminal",
            "サイドバー、入力、メニュー、コード、Terminal",
            "사이드바, 입력, 메뉴, 코드 및 Terminal"
        ),
        .init("Soft glass", "柔光玻璃", "ソフトガラス", "부드러운 유리"),
        .init("Spacing scale", "间距倍率", "間隔スケール", "간격 배율"),
        .init("Stop theme runtime", "停止主题 Runtime", "テーマRuntimeを停止", "테마 Runtime 중지"),
        .init("Stretch", "拉伸", "引き伸ばし", "늘이기"),
        .init("Success", "成功", "成功", "성공"),
        .init("Surface", "画面", "画面", "화면"),
        .init("Surface / bubble", "浮层／对话气泡", "サーフェス／吹き出し", "표면 / 말풍선"),
        .init("Surfaces", "界面表面", "サーフェス", "표면"),
        .init(
            "Switch between Home and Chat to inspect the center-panel boundary. Glass is approximated here; Codex uses the exact blur / saturation values.",
            "切换“首页”和“对话”以检查中央面板边界。此处仅近似显示玻璃效果；Codex 会使用精确的模糊／饱和度值。",
            "ホームとチャットを切り替えて中央パネルの境界を確認できます。ここでのガラス効果は近似表示で、Codexでは正確なぼかし／彩度の値が使われます。",
            "홈과 채팅을 전환하여 중앙 패널 경계를 확인하세요. 여기서는 유리 효과를 근사하며 Codex에서는 정확한 흐림/채도 값을 사용합니다."
        ),
        .init("Tags", "标签", "タグ", "태그"),
        .init("Terminal / Syntax Palette", "Terminal／语法调色板", "Terminal／構文パレット", "Terminal / 구문 팔레트"),
        .init("Terminal background", "Terminal 背景", "Terminalの背景", "Terminal 배경"),
        .init("Terminal text", "Terminal 文字", "Terminalの文字", "Terminal 텍스트"),
        .init("Text selection", "文字选择", "テキスト選択", "텍스트 선택"),
        .init("Text shadow", "文字阴影", "文字の影", "텍스트 그림자"),
        .init(
            "The most portable layer for shared themes",
            "分享主题时兼容性最高的一层",
            "共有テーマで最も移植性の高いレイヤー",
            "공유 테마에 가장 호환성이 높은 레이어"
        ),
        .init(
            "The preview uses the same theme data; verify expert selector rules in Codex.",
            "预览使用与真实 Codex 相同的主题数据；高级 selector 规则请在 Codex 中验证。",
            "プレビューは同じテーマデータを使用します。高度なselectorルールはCodexで確認してください。",
            "미리보기는 동일한 테마 데이터를 사용합니다. 고급 selector 규칙은 Codex에서 확인하세요."
        ),
        .init(
            "The wallpaper uses a click-through pseudo-element and never blocks Codex controls.",
            "壁纸使用可穿透点击的伪元素，绝不会阻挡 Codex 控件。",
            "壁紙はクリックを透過する疑似要素を使用し、Codexの操作を妨げません。",
            "배경화면은 클릭을 통과시키는 의사 요소를 사용하므로 Codex 컨트롤을 가리지 않습니다."
        ),
        .init("Theme deleted", "主题已删除", "テーマを削除しました", "테마를 삭제했습니다"),
        .init("Theme metadata", "主题信息", "テーマ情報", "테마 정보"),
        .init("Theme saved", "主题已保存", "テーマを保存しました", "테마를 저장했습니다"),
        .init("Theme template exported", "主题模板已导出", "テーマテンプレートを書き出しました", "테마 템플릿을 내보냈습니다"),
        .init("This is a built-in template", "这是内置模板", "これは組み込みテンプレートです", "기본 제공 템플릿입니다"),
        .init("Thread max width", "对话最大宽度", "スレッドの最大幅", "스레드 최대 너비"),
        .init("Tile", "平铺", "タイル", "타일"),
        .init(
            "Tint, shadow, blur, zoom, and motion",
            "色调、阴影、模糊、缩放和动画",
            "色合い、影、ぼかし、ズーム、モーション",
            "색조, 그림자, 흐림, 확대/축소 및 모션"
        ),
        .init("Titlebar", "标题栏", "タイトルバー", "제목 표시줄"),
        .init("Titlebar tint", "标题栏色调", "タイトルバーの色合い", "제목 표시줄 색조"),
        .init("Toolbar height", "工具栏高度", "ツールバーの高さ", "도구 막대 높이"),
        .init("Typography", "字体排印", "タイポグラフィ", "타이포그래피"),
        .init("UI font", "UI 字体", "UIフォント", "UI 글꼴"),
        .init("Undo", "撤销", "取り消す", "실행 취소"),
        .init("Unknown author", "未知作者", "作成者不明", "알 수 없는 작성자"),
        .init("Untitled Theme", "未命名主题", "名称未設定のテーマ", "이름 없는 테마"),
        .init("Use automatic colors", "使用自动配色", "自動配色を使用", "자동 색상 사용"),
        .init(
            "Use catalog components (app, sidebar, composer, codeBlock…) or supply any selectors. Property/value pairs are unrestricted.",
            "可使用目录组件（app、sidebar、composer、codeBlock…），也可提供任意 selector。property/value 对不受限制。",
            "カタログのコンポーネント（app、sidebar、composer、codeBlock…）を使うか、任意のselectorを指定できます。property/valueの組み合わせに制限はありません。",
            "카탈로그 컴포넌트(app, sidebar, composer, codeBlock…)를 사용하거나 임의의 selector를 지정할 수 있습니다. property/value 쌍에는 제한이 없습니다."
        ),
        .init(
            "Unset colors follow Primary text and Cards / menus.",
            "未指定的颜色会沿用“主要文字”和“卡片／菜单”。",
            "未指定の色は「メインテキスト」と「カード／メニュー」に従います。",
            "지정하지 않은 색상은 기본 텍스트 및 카드 / 메뉴 색상을 따릅니다."
        ),
        .init(
            "Use the image's natural size; focal point controls placement.",
            "使用图像原始尺寸；焦点控制放置位置。",
            "画像を元のサイズで使用し、フォーカルポイントで配置を調整します。",
            "이미지의 원본 크기를 사용하며 초점으로 배치 위치를 조절합니다."
        ),
        .init(
            "Values map directly to Codex tokens, so variable fonts, clamp(), calc(), custom shadows, and motion are all supported.",
            "数值会直接映射到 Codex token，因此支持可变字体、clamp()、calc()、自定义阴影和动画。",
            "値はCodexトークンに直接割り当てられるため、可変フォント、clamp()、calc()、カスタムの影、モーションをすべて利用できます。",
            "값은 Codex 토큰에 직접 매핑되므로 가변 글꼴, clamp(), calc(), 사용자 지정 그림자 및 모션을 모두 지원합니다."
        ),
        .init("Version", "版本", "バージョン", "버전"),
        .init("Vertical focal point", "垂直焦点", "垂直フォーカルポイント", "세로 초점"),
        .init("Vertical padding", "垂直内边距", "垂直パディング", "세로 안쪽 여백"),
        .init("Vertical tile origin", "垂直平铺起点", "垂直タイル原点", "세로 타일 원점"),
        .init("Vignette", "暗角", "ビネット", "비네팅"),
        .init("Warning", "警告", "警告", "경고"),
        .init("Wide block max width", "宽内容最大宽度", "ワイドブロックの最大幅", "넓은 블록 최대 너비"),
        .init(
            "Wraps only the Home heading or Chat transcript, without changing suggestion cards, the Composer, or the full main-content background.",
            "仅包裹首页标题或对话内容，不会更改建议卡片、Composer 或整个主内容背景。",
            "ホームの見出しまたはチャット履歴だけを囲み、候補カード、Composer、メインコンテンツ全体の背景には影響しません。",
            "홈 제목 또는 채팅 내용만 감싸며 제안 카드, Composer 또는 전체 기본 콘텐츠 배경은 변경하지 않습니다."
        ),
        .init("dark, glass, neon", "深色、玻璃、霓虹", "ダーク、ガラス、ネオン", "다크, 유리, 네온"),
        .init("selectors, comma-separated", "selector，以逗号分隔", "selector（カンマ区切り）", "selector, 쉼표로 구분"),

        // Dynamic format strings.
        .init("Undo {0}", "撤销 {0}", "{0}を取り消す", "{0} 실행 취소"),
        .init("Redo {0}", "重做 {0}", "{0}をやり直す", "{0} 다시 실행"),
        .init("Undo: {0} (⌘Z)", "撤销：{0}（⌘Z）", "取り消す：{0}（⌘Z）", "실행 취소: {0}(⌘Z)"),
        .init("Redo: {0} (⇧⌘Z)", "重做：{0}（⇧⌘Z）", "やり直す：{0}（⇧⌘Z）", "다시 실행: {0}(⇧⌘Z)"),
        .init("{0} component overrides", "{0} 个组件覆盖", "コンポーネント上書き：{0}件", "컴포넌트 재정의 {0}개"),
        .init("Attached · “{0}” active", "已连接 · “{0}”使用中", "接続済み・「{0}」を使用中", "연결됨 · ‘{0}’ 사용 중"),
        .init(
            "Attaching will restore “{0}”. Codex may restart if CDP is not enabled.",
            "连接后将恢复“{0}”。如果未启用 CDP，Codex 可能会重新启动。",
            "接続すると「{0}」を復元します。CDPが有効でない場合、Codexが再起動することがあります。",
            "연결하면 ‘{0}’을(를) 복원합니다. CDP가 활성화되지 않은 경우 Codex가 다시 시작될 수 있습니다."
        ),
        .init(
            "Codex attached. Restored “{0}”.",
            "已连接 Codex，并恢复“{0}”。",
            "Codexに接続し、「{0}」を復元しました。",
            "Codex에 연결하고 ‘{0}’을(를) 복원했습니다."
        ),
        .init("Applied “{0}”", "已应用“{0}”", "「{0}」を適用しました", "‘{0}’ 적용됨"),
        .init("Imported “{0}”", "已导入“{0}”", "「{0}」を読み込みました", "‘{0}’ 가져옴"),
        .init("Added {0} asset", "已添加 {0} 个素材", "アセットを{0}件追加しました", "에셋 {0}개 추가됨"),
        .init("Added {0} assets", "已添加 {0} 个素材", "アセットを{0}件追加しました", "에셋 {0}개 추가됨"),
        .init("{0} background set", "已设置{0}背景", "{0}の背景を設定しました", "{0} 배경 설정됨"),
        .init("Copy {0} to {1}", "将{0}复制到{1}", "{0}を{1}にコピー", "{0}을(를) {1}(으)로 복사"),
        .init("Copy to {0}", "复制到{0}", "{0}にコピー", "{0}(으)로 복사"),
        .init(
            "Asset “{0}” is larger than 16 MB.",
            "素材“{0}”大于 16 MB。",
            "アセット「{0}」は16 MBを超えています。",
            "에셋 ‘{0}’의 크기가 16MB를 초과합니다."
        ),
        .init(
            "Assets would total {0}, above the 32 MB limit.",
            "添加后素材总量将达到 {0}，超过 32 MB 上限。",
            "アセットの合計が{0}となり、32 MBの上限を超えます。",
            "에셋 전체 크기가 {0}이 되어 32MB 제한을 초과합니다."
        ),
        .init(
            "“{0}” is not a decodable PNG, JPEG, WebP, GIF, or AVIF image.",
            "“{0}”不是可解码的 PNG、JPEG、WebP、GIF 或 AVIF 图像。",
            "「{0}」はデコード可能なPNG、JPEG、WebP、GIF、AVIF画像ではありません。",
            "‘{0}’은(는) 디코딩 가능한 PNG, JPEG, WebP, GIF 또는 AVIF 이미지가 아닙니다."
        ),

        // Shared navigation and actions.
        .init("Codex Theme Switcher", "Codex 主题切换器", "Codexテーマスイッチャー", "Codex 테마 전환기"),
        .init("Themes", "主题库", "テーマ", "테마"),
        .init("Preview", "预览", "プレビュー", "미리보기"),
        .init("Skin", "背景与玻璃", "背景とガラス", "배경 및 유리"),
        .init("Colors", "色彩", "カラー", "색상"),
        .init("Type & Layout", "字体与布局", "文字とレイアウト", "글꼴 및 레이아웃"),
        .init("Components", "组件", "コンポーネント", "컴포넌트"),
        .init("Rules", "规则", "ルール", "규칙"),
        .init("Advanced CSS", "高级 CSS", "高度なCSS", "고급 CSS"),
        .init("Assets", "素材", "アセット", "에셋"),
        .init("Info", "信息", "情報", "정보"),
        .init("Apply", "应用", "適用", "적용"),
        .init("Save", "保存", "保存", "저장"),
        .init("Rename", "重命名", "名前を変更", "이름 변경"),
        .init("Rename theme", "重命名主题", "テーマ名を変更", "테마 이름 변경"),
        .init("Theme name", "主题名称", "テーマ名", "테마 이름"),
        .init("Make editable copy", "创建可编辑副本", "編集可能なコピーを作成", "편집 가능한 복사본 만들기"),
        .init("Import", "导入", "読み込む", "가져오기"),
        .init("Export", "导出", "書き出す", "내보내기"),
        .init("Launch + Attach Codex", "启动并连接 Codex", "Codexを起動して接続", "Codex 실행 및 연결"),
        .init("Restore Codex style", "恢复 Codex 原始样式", "Codexのスタイルに戻す", "Codex 스타일 복원"),
        .init("Quit", "退出", "終了", "종료"),
        .init("New theme", "新建主题", "新規テーマ", "새 테마"),

        // Preview content and Codex surface labels.
        .init("Home", "首页", "ホーム", "홈"),
        .init("Chat", "对话", "チャット", "채팅"),
        .init("Projects", "项目", "プロジェクト", "프로젝트"),
        .init("Settings", "设置", "設定", "설정"),
        .init("About {0}", "关于 {0}", "{0}について", "{0} 정보"),
        .init("New task", "新建任务", "新しいタスク", "새 작업"),
        .init("Scheduled", "计划任务", "スケジュール", "예약됨"),
        .init("Plugins", "插件", "プラグイン", "플러그인"),
        .init("Pull requests", "拉取请求", "プルリクエスト", "풀 리퀘스트"),
        .init("What should we build?", "我们来构建什么？", "何を作りましょうか？", "무엇을 만들어 볼까요?"),
        .init("Select project", "选择项目", "プロジェクトを選択", "프로젝트 선택"),
        .init("Explore and understand code", "探索并理解代码", "コードを調べて理解する", "코드 탐색 및 이해"),
        .init("Build a new feature", "构建新功能", "新機能を構築する", "새 기능 구축"),
        .init("Review and suggest changes", "审查并建议更改", "レビューして変更を提案する", "검토 및 변경 사항 제안"),
        .init("Fix issues and failures", "修复问题与故障", "問題や障害を修正する", "문제 및 오류 수정"),
        .init("Ask Codex anything", "向 Codex 提出任何问题", "Codexに何でも質問", "Codex에 무엇이든 질문"),
        .init("Do anything", "输入任何任务", "何でも依頼", "무엇이든 요청"),
        .init("Composer", "Composer", "Composer", "Composer"),
        .init("Theme applied", "主题已应用", "テーマを適用しました", "테마 적용됨"),
        .init(
            "All open Codex renderer surfaces are synchronized.",
            "所有打开的 Codex renderer 画面均已同步。",
            "開いているすべてのCodex renderer画面を同期しました。",
            "열려 있는 모든 Codex renderer 화면이 동기화되었습니다."
        ),
        .init(
            "Make the customization as flexible as possible.",
            "尽可能提供灵活的定制能力。",
            "できる限り柔軟にカスタマイズできるようにします。",
            "가능한 한 유연하게 사용자 지정할 수 있도록 합니다."
        ),
        .init(
            "I’ll turn this into a menu bar app with live theme switching, a visual skin editor, and portable templates.",
            "我会将它打造成一款菜单栏应用，支持实时主题切换、可视化皮肤编辑器和可移植模板。",
            "リアルタイムのテーマ切り替え、ビジュアルスキンエディタ、持ち運べるテンプレートを備えたメニューバーアプリにします。",
            "실시간 테마 전환, 시각적 스킨 편집기 및 휴대 가능한 템플릿을 갖춘 메뉴 막대 앱으로 만들겠습니다."
        ),

        // Additional editor and preview terminology.
        .init("Always", "始终", "常に", "항상"),
        .init("Base", "基础", "ベース", "기본"),
        .init("CSS color", "CSS 颜色", "CSSカラー", "CSS 색상"),
        .init("CSS value", "CSS 值", "CSS値", "CSS 값"),
        .init("Custom", "自定义", "カスタム", "사용자 지정"),
        .init("Image skin studio", "图像皮肤工作室", "画像スキンスタジオ", "이미지 스킨 스튜디오"),
        .init("Multiply", "正片叠底", "乗算", "곱하기"),
        .init("Normal", "正常", "通常", "일반"),
        .init("Overlay", "叠加", "オーバーレイ", "오버레이"),
        .init("Property", "属性", "プロパティ", "속성"),
        .init("Screen", "滤色", "スクリーン", "스크린"),
        .init("Shareable templates", "可分享模板", "共有可能なテンプレート", "공유 가능한 템플릿"),
        .init("Soft Light", "柔光", "ソフトライト", "소프트 라이트"),
        .init("{0} component override", "{0} 个组件覆盖", "コンポーネント上書き：{0}件", "컴포넌트 재정의 {0}개"),
        .init("{0} · {1} rule", "{0} · {1} 条规则", "{0}・ルール{1}件", "{0} · 규칙 {1}개"),
        .init("{0} · {1} rules", "{0} · {1} 条规则", "{0}・ルール{1}件", "{0} · 규칙 {1}개"),

        // Localized application and runtime errors.
        .init(
            "A compatible Node.js runtime was not found.",
            "找不到兼容的 Node.js runtime。",
            "互換性のあるNode.js runtimeが見つかりません。",
            "호환되는 Node.js runtime을 찾을 수 없습니다."
        ),
        .init(
            "A theme asset is invalid.",
            "主题素材无效。",
            "テーマアセットが無効です。",
            "테마 에셋이 유효하지 않습니다."
        ),
        .init(
            "A theme asset is too large.",
            "主题素材过大。",
            "テーマアセットが大きすぎます。",
            "테마 에셋이 너무 큽니다."
        ),
        .init(
            "Built-in theme {0} cannot be deleted.",
            "无法删除内置主题 {0}。",
            "組み込みテーマ{0}は削除できません。",
            "기본 제공 테마 {0}은(는) 삭제할 수 없습니다."
        ),
        .init(
            "Built-in theme {0} cannot be replaced.",
            "无法替换内置主题 {0}。",
            "組み込みテーマ{0}は置き換えられません。",
            "기본 제공 테마 {0}은(는) 교체할 수 없습니다."
        ),
        .init(
            "CSS references missing theme asset {0}.",
            "CSS 引用了不存在的主题素材 {0}。",
            "CSSが存在しないテーマアセット{0}を参照しています。",
            "CSS가 존재하지 않는 테마 에셋 {0}을(를) 참조합니다."
        ),
        .init(
            "Could not communicate with Codex.",
            "无法与 Codex 通信。",
            "Codexと通信できませんでした。",
            "Codex와 통신할 수 없습니다."
        ),
        .init(
            "Could not communicate with the Codex renderer.",
            "无法与 Codex renderer 通信。",
            "Codex rendererと通信できませんでした。",
            "Codex renderer와 통신할 수 없습니다."
        ),
        .init(
            "Malformed theme asset reference: {0}",
            "主题素材引用格式错误：{0}",
            "テーマアセット参照の形式が正しくありません：{0}",
            "테마 에셋 참조 형식이 잘못되었습니다: {0}"
        ),
        .init(
            "No attachable Codex renderer was found.",
            "找不到可连接的 Codex renderer。",
            "接続可能なCodex rendererが見つかりません。",
            "연결할 수 있는 Codex renderer를 찾을 수 없습니다."
        ),
        .init(
            "Operation failed: {0}",
            "操作失败：{0}",
            "操作に失敗しました：{0}",
            "작업 실패: {0}"
        ),
        .init(
            "The Codex app could not be found.",
            "找不到 Codex App。",
            "Codexアプリが見つかりません。",
            "Codex 앱을 찾을 수 없습니다."
        ),
        .init(
            "The selected application is not a valid Codex app.",
            "所选 App 不是有效的 Codex。",
            "選択したアプリは有効なCodexアプリではありません。",
            "선택한 앱은 유효한 Codex 앱이 아닙니다."
        ),
        .init(
            "The Codex runtime operation failed.",
            "Codex runtime 操作失败。",
            "Codex runtimeの操作に失敗しました。",
            "Codex runtime 작업에 실패했습니다."
        ),
        .init(
            "The bundled Codex Theme runtime helper was not found.",
            "找不到内附的 Codex Theme runtime helper。",
            "同梱のCodex Theme runtime helperが見つかりません。",
            "포함된 Codex Theme runtime helper를 찾을 수 없습니다."
        ),
        .init(
            "The runtime command is invalid.",
            "Runtime 命令无效。",
            "Runtimeコマンドが無効です。",
            "Runtime 명령이 유효하지 않습니다."
        ),
        .init(
            "The runtime endpoint was not found.",
            "找不到 Runtime 端点。",
            "Runtimeエンドポイントが見つかりません。",
            "Runtime 엔드포인트를 찾을 수 없습니다."
        ),
        .init(
            "The runtime rejected the request.",
            "Runtime 拒绝了该请求。",
            "Runtimeがリクエストを拒否しました。",
            "Runtime이 요청을 거부했습니다."
        ),
        .init(
            "The theme CSS contains unsafe content.",
            "主题 CSS 包含不安全的内容。",
            "テーマCSSに安全でない内容が含まれています。",
            "테마 CSS에 안전하지 않은 콘텐츠가 포함되어 있습니다."
        ),
        .init(
            "The theme archive could not be read.",
            "无法读取主题归档文件。",
            "テーマアーカイブを読み込めませんでした。",
            "테마 아카이브를 읽을 수 없습니다."
        ),
        .init(
            "The theme archive is {0} bytes; the maximum is {1} bytes.",
            "主题归档文件为 {0} 字节；上限为 {1} 字节。",
            "テーマアーカイブは{0}バイトです。上限は{1}バイトです。",
            "테마 아카이브의 크기는 {0}바이트이며 최대 크기는 {1}바이트입니다."
        ),
        .init(
            "The theme assets are too large in total.",
            "主题素材总容量过大。",
            "テーマアセットの合計サイズが大きすぎます。",
            "테마 에셋의 전체 크기가 너무 큽니다."
        ),
        .init(
            "The theme contains an unreferenced asset.",
            "主题包含未被引用的素材。",
            "テーマに参照されていないアセットが含まれています。",
            "테마에 참조되지 않은 에셋이 포함되어 있습니다."
        ),
        .init(
            "The theme data is invalid.",
            "主题数据无效。",
            "テーマデータが無効です。",
            "테마 데이터가 유효하지 않습니다."
        ),
        .init(
            "The theme data is too large.",
            "主题数据过大。",
            "テーマデータが大きすぎます。",
            "테마 데이터가 너무 큽니다."
        ),
        .init(
            "The theme references a missing asset.",
            "主题引用了不存在的素材。",
            "テーマが存在しないアセットを参照しています。",
            "테마가 존재하지 않는 에셋을 참조합니다."
        ),
        .init(
            "Theme file {0} is corrupt or unsupported.",
            "主题文件 {0} 已损坏或不受支持。",
            "テーマファイル{0}は破損しているか、対応していません。",
            "테마 파일 {0}이(가) 손상되었거나 지원되지 않습니다."
        ),
        .init(
            "Theme validation failed.",
            "主题验证失败。",
            "テーマの検証に失敗しました。",
            "테마 검증에 실패했습니다."
        ),
        .init(
            "Theme validation failed. Check: {0}",
            "主题验证失败。请检查：{0}",
            "テーマの検証に失敗しました。次を確認してください：{0}",
            "테마 검증에 실패했습니다. 다음을 확인하세요: {0}"
        ),
        .init(
            "Theme {0} already exists.",
            "主题 {0} 已存在。",
            "テーマ{0}はすでに存在します。",
            "테마 {0}이(가) 이미 존재합니다."
        ),
        .init(
            "Theme {0} cannot be made active because it does not exist.",
            "主题 {0} 不存在，无法设为使用中。",
            "テーマ{0}は存在しないため、有効にできません。",
            "테마 {0}이(가) 존재하지 않아 활성화할 수 없습니다."
        ),
        .init(
            "Theme {0} was not found.",
            "找不到主题 {0}。",
            "テーマ{0}が見つかりません。",
            "테마 {0}을(를) 찾을 수 없습니다."
        ),
        .init(
            "Unsupported theme archive format: {0}.",
            "不支持的主题归档格式：{0}。",
            "対応していないテーマアーカイブ形式です：{0}。",
            "지원되지 않는 테마 아카이브 형식입니다: {0}."
        ),
        .init(
            "Manage the interface language, Codex application, and update preferences.",
            "管理界面语言、Codex App 位置和更新偏好。",
            "インターフェイス言語、Codex Appの場所、アップデート設定を管理します。",
            "인터페이스 언어, Codex 앱 위치 및 업데이트 설정을 관리합니다."
        ),
        .init("Current version", "当前版本", "現在のバージョン", "현재 버전"),
        .init("Version {0} ({1})", "版本 {0}（{1}）", "バージョン{0}（{1}）", "버전 {0} ({1})"),
        .init("Automatic update checks", "自动检查更新", "アップデートを自動確認", "자동 업데이트 확인"),
        .init(
            "Checks at launch and every 30 minutes.",
            "启动时检查，之后每 30 分钟检查一次。",
            "起動時と、その後30分ごとに確認します。",
            "실행할 때와 이후 30분마다 확인합니다."
        ),
        .init("Update channel", "更新通道", "アップデートチャンネル", "업데이트 채널"),
        .init("Stable", "正式版", "安定版", "안정 버전"),
        .init("Beta", "Beta", "ベータ版", "베타"),
        .init("Recommended releases.", "推荐版本。", "推奨リリースです。", "권장 릴리스입니다."),
        .init(
            "Prerelease builds may be less stable.",
            "预发布版本可能不够稳定。",
            "プレリリースビルドは安定性が低い場合があります。",
            "사전 릴리스 빌드는 안정성이 낮을 수 있습니다."
        ),
        .init("Check for Updates…", "检查更新…", "アップデートを確認…", "업데이트 확인…"),
        .init("Checking for updates…", "正在检查更新…", "アップデートを確認中…", "업데이트 확인 중…"),
        .init(
            "You're up to date ({0}).",
            "当前已是最新版本（{0}）。",
            "最新の状態です（{0}）。",
            "최신 버전입니다({0})."
        ),
        .init(
            "Version {0} is available.",
            "版本 {0} 现已可用。",
            "バージョン{0}を利用できます。",
            "버전 {0}을(를) 사용할 수 있습니다."
        ),
        .init(
            "Update check failed: {0}",
            "检查更新失败：{0}",
            "アップデートの確認に失敗しました：{0}",
            "업데이트 확인 실패: {0}"
        ),
        .init("Update available", "有可用更新", "アップデートがあります", "사용 가능한 업데이트"),
        .init("Install update", "安装更新", "アップデートをインストール", "업데이트 설치"),
        .init("Download manually", "手动下载", "手動でダウンロード", "수동 다운로드"),
        .init("Skip this version", "跳过此版本", "このバージョンをスキップ", "이 버전 건너뛰기"),
        .init("Later", "稍后", "後で", "나중에"),
        .init("Release notes", "更新说明", "リリースノート", "릴리스 노트"),
        .init(
            "No release notes were provided.",
            "此版本未提供更新说明。",
            "リリースノートは提供されていません。",
            "릴리스 노트가 제공되지 않았습니다."
        ),
        .init("Published {0}", "发布于 {0}", "{0}に公開", "{0}에 게시"),
        .init("Powered by Sparkle", "由 Sparkle 提供支持", "Sparkleを使用", "Sparkle 제공"),
        .init("Show What's New", "查看新功能", "新機能を表示", "새로운 기능 보기"),
        .init("What's New in {0}", "{0} 新功能", "{0}の新機能", "{0}의 새로운 기능"),
        .init(
            "Theme updates, your way.",
            "主题更新，由你选择。",
            "テーマのアップデートを、あなたらしく。",
            "원하는 방식으로 테마를 업데이트하세요."
        ),
        .init(
            "Follow your Mac automatically or choose from seven interface languages.",
            "可自动跟随 Mac，或手动选择七种界面语言。",
            "Macの設定に自動で合わせるか、7つのインターフェイス言語から選択できます。",
            "Mac 언어를 자동으로 따르거나 7개 인터페이스 언어 중에서 선택할 수 있습니다."
        ),
        .init(
            "Choose Stable or Beta updates from Settings.",
            "可在“设置”中选择正式版或 Beta 更新。",
            "設定から安定版またはベータ版のアップデートを選択できます。",
            "설정에서 안정 버전 또는 베타 업데이트를 선택하세요."
        ),
        .init(
            "Sparkle verifies and installs signed app updates.",
            "Sparkle 会验证并安装已签名的 App 更新。",
            "Sparkleが署名済みのAppアップデートを検証してインストールします。",
            "Sparkle이 서명된 앱 업데이트를 확인하고 설치합니다."
        ),
        .init("Done", "完成", "完了", "완료"),
        .init("Open Releases", "打开 Releases", "リリースを開く", "릴리스 열기"),
        .init(
            "Invalid update response.",
            "更新响应无效。",
            "アップデートの応答が無効です。",
            "업데이트 응답이 올바르지 않습니다."
        ),
        .init(
            "Failed to decode update metadata.",
            "无法解析更新元数据。",
            "アップデートメタデータのデコードに失敗しました。",
            "업데이트 메타데이터를 디코딩하지 못했습니다."
        ),
        .init(
            "No update is available on this channel.",
            "此更新通道暂无可用更新。",
            "このチャンネルで利用できるアップデートはありません。",
            "이 채널에서 사용할 수 있는 업데이트가 없습니다."
        ),
        .init(
            "Unable to start Sparkle. Open the download page instead.",
            "无法启动 Sparkle。请改为打开下载页面。",
            "Sparkleを起動できません。代わりにダウンロードページを開いてください。",
            "Sparkle을 시작할 수 없습니다. 대신 다운로드 페이지를 여세요."
        ),
        .init(
            "Sparkle is available in the packaged app.",
            "Sparkle 可在打包后的 App 中使用。",
            "Sparkleはパッケージ版Appで利用できます。",
            "Sparkle은 패키징된 앱에서 사용할 수 있습니다."
        ),
        .init(
            "Sparkle is unavailable when running from SwiftPM.",
            "从 SwiftPM 运行时无法使用 Sparkle。",
            "SwiftPMからの実行中はSparkleを利用できません。",
            "SwiftPM에서 실행 중일 때는 Sparkle을 사용할 수 없습니다."
        ),
        .init("Automatic checks are off.", "自动检查已关闭。", "自動確認はオフです。", "자동 확인이 꺼져 있습니다."),
        .init(
            "Unsupported theme archive version: {0}.",
            "不支持的主题归档版本：{0}。",
            "対応していないテーマアーカイブのバージョンです：{0}。",
            "지원되지 않는 테마 아카이브 버전입니다: {0}."
        ),
        .init(
            "Choose Codex application",
            "选择 Codex App",
            "Codex Appを選択",
            "Codex 앱 선택"
        ),
        .init("Choose", "选择", "選択", "선택"),
        .init("Codex application", "Codex App", "Codex App", "Codex 앱"),
        .init(
            "Automatically finds a running or installed Codex, or lets you choose another location.",
            "自动查找正在运行或已安装的 Codex，也可指定其他位置。",
            "実行中またはインストール済みのCodexを自動検出し、別の場所を指定することもできます。",
            "실행 중이거나 설치된 Codex를 자동으로 찾고 다른 위치를 선택할 수도 있습니다."
        ),
        .init(
            "Using a custom location",
            "正在使用自定义位置",
            "カスタム場所を使用中",
            "사용자 지정 위치 사용 중"
        ),
        .init(
            "Codex detected automatically",
            "已自动找到 Codex",
            "Codexを自動検出しました",
            "Codex 자동 감지됨"
        ),
        .init(
            "Codex application not found",
            "找不到 Codex App",
            "Codex Appが見つかりません",
            "Codex 앱을 찾을 수 없음"
        ),
        .init("Choose…", "选择…", "選択…", "선택…"),
        .init(
            "Use Automatic",
            "改用自动检测",
            "自動検出を使用",
            "자동 감지 사용"
        ),
        .init(
            "Codex application location saved",
            "已保存 Codex App 位置",
            "Codex Appの場所を保存しました",
            "Codex 앱 위치를 저장했습니다"
        ),
        .init(
            "Automatic Codex discovery enabled",
            "已启用 Codex 自动检测",
            "Codexの自動検出を有効にしました",
            "Codex 자동 감지를 사용합니다"
        ),
        .init(
            "Interface language",
            "界面语言",
            "インターフェイス言語",
            "인터페이스 언어"
        ),
        .init(
            "Follow your Mac automatically or choose a language for this app.",
            "自动跟随 Mac，或为此 App 选择语言。",
            "Macの設定に自動で合わせるか、このAppで使用する言語を選択します。",
            "Mac 언어를 자동으로 따르거나 이 앱에서 사용할 언어를 선택하세요."
        ),
        .init(
            "Automatic (System)",
            "自动（跟随系统）",
            "自動（システム）",
            "자동(시스템)"
        ),
        .init(
            "Language changes take effect immediately.",
            "语言更改会立即生效。",
            "言語の変更はすぐに反映されます。",
            "언어 변경 사항은 즉시 적용됩니다."
        ),
        .init(
            "“{0}” is not a valid Codex application.",
            "“{0}”不是有效的 Codex App。",
            "「{0}」は有効なCodex Appではありません。",
            "“{0}”은(는) 올바른 Codex 앱이 아닙니다."
        ),
        .init("Voice", "Voice", "Voice", "Voice"),
        .init(
            "Customize the ChatGPT Voice orb and surrounding effects. The custom orb appears both in the main window and the isolated Voice overlay; full-page backgrounds remain isolated.",
            "自定义 ChatGPT Voice 圆球与周边效果。自定义圆球会同时显示在主窗口和独立 Voice 浮层中；全页背景仍只用于独立浮层。",
            "ChatGPT Voiceのオーブと周辺効果をカスタマイズします。カスタムオーブはメインウインドウと独立したVoiceオーバーレイの両方に表示され、全画面背景はオーバーレイ内だけに適用されます。",
            "ChatGPT Voice 오브와 주변 효과를 사용자 지정합니다. 사용자 지정 오브는 기본 창과 독립 Voice 오버레이 모두에 표시되며, 전체 화면 배경은 오버레이에만 적용됩니다."
        ),
        .init(
            "Enable Voice styling",
            "启用 Voice 样式",
            "Voiceスタイルを有効化",
            "Voice 스타일 활성화"
        ),
        .init(
            "Disable Voice styling",
            "停用 Voice 样式",
            "Voiceスタイルを無効化",
            "Voice 스타일 비활성화"
        ),
        .init("Experimental", "实验功能", "実験的機能", "실험 기능"),
        .init(
            "Codex versions may use DOM, Canvas, WebGL, or native layers. The embedded image works on the current DOM orb, while native or Canvas orbs may not expose their inside to CSS.",
            "不同 Codex 版本可能使用 DOM、Canvas、WebGL 或原生图层。内嵌图像适用于当前 DOM 圆球，但原生或 Canvas 圆球可能不会向 CSS 开放内部。",
            "CodexのバージョンによってDOM、Canvas、WebGL、またはネイティブレイヤーが使われます。埋め込み画像は現在のDOMオーブで動作しますが、ネイティブまたはCanvasのオーブ内部はCSSから操作できない場合があります。",
            "Codex 버전에 따라 DOM, Canvas, WebGL 또는 네이티브 레이어를 사용할 수 있습니다. 삽입 이미지는 현재 DOM 오브에서 작동하지만 네이티브 또는 Canvas 오브 내부는 CSS에 노출되지 않을 수 있습니다."
        ),
        .init(
            "Reset current appearance",
            "重置当前外观",
            "現在の外観をリセット",
            "현재 모양 재설정"
        ),
        .init(
            "Remove Voice style",
            "移除 Voice 样式",
            "Voiceスタイルを削除",
            "Voice 스타일 제거"
        ),
        .init("Effect preview", "效果预览", "効果プレビュー", "효과 미리보기"),
        .init(
            "The preview uses the measured Voice overlay ratio and initial orb position. Its runtime position can differ after you drag the orb.",
            "预览使用实测的 Voice overlay 比例与圆球初始位置；拖动圆球后，实际位置可能不同。",
            "プレビューは実測したVoice overlayの比率とオーブの初期位置を使用します。オーブをドラッグした後は実際の位置が異なる場合があります。",
            "미리보기는 측정된 Voice overlay 비율과 오브의 초기 위치를 사용합니다. 오브를 드래그한 뒤 실제 위치는 달라질 수 있습니다."
        ),
        .init("Orb surface", "圆球表面", "オーブ表面", "오브 표면"),
        .init(
            "Native orb opacity",
            "原生圆球不透明度",
            "元のオーブの不透明度",
            "기본 오브 불투명도"
        ),
        .init(
            "Applied to Canvas and recognizable orb containers inside the Voice overlay.",
            "应用到 Voice overlay 中可识别的 Canvas 与圆球容器。",
            "Voice overlay内のCanvasと認識可能なオーブコンテナに適用されます。",
            "Voice overlay 안의 Canvas와 인식 가능한 오브 컨테이너에 적용됩니다."
        ),
        .init("Scale", "缩放", "拡大縮小", "크기 조절"),
        .init("Hue rotation", "色相旋转", "色相回転", "색조 회전"),
        .init("Blur", "模糊", "ぼかし", "흐림"),
        .init("Outer glow", "外围光晕", "外側グロー", "외부 광선"),
        .init("Glow color", "光晕颜色", "グローの色", "광선 색상"),
        .init("Glow opacity", "光晕不透明度", "グローの不透明度", "광선 불투명도"),
        .init("Glow spread", "光晕范围", "グローの広がり", "광선 범위"),
        .init("Voice backdrop", "Voice 背景", "Voice背景", "Voice 배경"),
        .init(
            "Transparent by default. Raising opacity adds a tint behind the Voice overlay.",
            "默认完全透明。提高不透明度会在 Voice overlay 后方加入底色。",
            "既定では完全に透明です。不透明度を上げるとVoice overlayの背後に色が付きます。",
            "기본값은 완전 투명입니다. 불투명도를 높이면 Voice overlay 뒤에 색상이 추가됩니다."
        ),
        .init("Backdrop color", "背景颜色", "背景色", "배경 색상"),
        .init("Backdrop opacity", "背景不透明度", "背景の不透明度", "배경 불투명도"),
        .init(
            "Voice Advanced CSS",
            "Voice 高级 CSS",
            "Voice高度なCSS",
            "Voice 고급 CSS"
        ),
        .init(
            "Delivered only to avatar-overlay, never the main Codex window. theme-asset(\"UUID\") is supported; imports, external URLs, and file URLs remain blocked.",
            "只会传送到 avatar-overlay，不会进入 Codex 主窗口。支持 theme-asset(\"UUID\")；仍会阻止导入、外部 URL 与 file URL。",
            "avatar-overlayのみに送られ、Codexのメインウインドウには入りません。theme-asset(\"UUID\")を使用できますが、import、外部URL、file URLは引き続き拒否されます。",
            "avatar-overlay에만 전달되며 Codex 기본 창에는 적용되지 않습니다. theme-asset(\"UUID\")를 지원하지만 import, 외부 URL 및 file URL은 계속 차단됩니다."
        ),
        .init(
            "Copy Voice appearance",
            "复制 Voice 外观",
            "Voiceの外観をコピー",
            "Voice 모양 복사"
        ),
        .init(
            "Reset Voice appearance",
            "重置 Voice 外观",
            "Voiceの外観をリセット",
            "Voice 모양 재설정"
        ),
        .init(
            "Voice renderer connected",
            "Voice renderer 已连接",
            "Voice rendererに接続済み",
            "Voice renderer 연결됨"
        ),
        .init(
            "Waiting for a Voice conversation",
            "等待开启 Voice 对话",
            "Voice会話の開始を待機中",
            "Voice 대화 시작 대기 중"
        ),
        .init(
            "Voice background image",
            "Voice 背景图像",
            "Voice背景画像",
            "Voice 배경 이미지"
        ),
        .init(
            "Keep orb centered in Voice overlay",
            "将圆球固定在 Voice 画面中央",
            "オーブをVoice画面の中央に固定",
            "오브를 Voice 화면 중앙에 고정"
        ),
        .init(
            "Turn this off to use ChatGPT's native dragging and move the orb to screen edges.",
            "关闭后可使用 ChatGPT 原生拖动，将圆球移到屏幕边缘。",
            "オフにするとChatGPT標準のドラッグ操作でオーブを画面端まで移動できます。",
            "끄면 ChatGPT 기본 드래그를 사용하여 오브를 화면 가장자리로 이동할 수 있습니다."
        ),
        .init(
            "Light and Dark can use different images. The image is embedded in the .codextheme and sent only to the Voice overlay.",
            "浅色与深色可使用不同图像。图像会嵌入 .codextheme，并且只发送到 Voice overlay。",
            "LightとDarkで別々の画像を使用できます。画像は.codexthemeに埋め込まれ、Voice overlayのみに送信されます。",
            "Light와 Dark에 서로 다른 이미지를 사용할 수 있습니다. 이미지는 .codextheme에 포함되며 Voice overlay에만 전송됩니다."
        ),
        .init(
            "Choose light Voice background",
            "选择浅色 Voice 背景",
            "LightのVoice背景を選択",
            "Light Voice 배경 선택"
        ),
        .init(
            "Choose dark Voice background",
            "选择深色 Voice 背景",
            "DarkのVoice背景を選択",
            "Dark Voice 배경 선택"
        ),
        .init(
            "{0} Voice background set",
            "已设置{0} Voice 背景",
            "{0}のVoice背景を設定しました",
            "{0} Voice 배경 설정됨"
        ),
        .init(
            "Adjust Voice background focal point",
            "调整 Voice 背景焦点",
            "Voice背景のフォーカルポイントを調整",
            "Voice 배경 초점 조정"
        ),
        .init(
            "Image inside orb",
            "圆球内部图像",
            "オーブ内の画像",
            "오브 내부 이미지"
        ),
        .init(
            "Places a separate image inside the current DOM orb. Lower the image opacity to let the original animated orb show through.",
            "在当前 DOM 圆球内放置独立图像。降低图像不透明度可让原本的动画圆球透出。",
            "現在のDOMオーブ内に別の画像を配置します。画像の不透明度を下げると、元のアニメーションオーブが透けて見えます。",
            "현재 DOM 오브 안에 별도 이미지를 배치합니다. 이미지 불투명도를 낮추면 원래의 애니메이션 오브가 비쳐 보입니다."
        ),
        .init(
            "Follow Voice pulse",
            "跟随 Voice 脉动",
            "Voiceの脈動に追従",
            "Voice 맥동 따라가기"
        ),
        .init(
            "Synchronizes the orb image scale with the native Voice animation.",
            "让圆球图像跟随原生 Voice 动画同步缩放。",
            "オーブ画像の拡大縮小をネイティブVoiceアニメーションと同期します。",
            "오브 이미지 크기를 기본 Voice 애니메이션과 동기화합니다."
        ),
        .init(
            "Pulse strength",
            "脉动强度",
            "脈動の強さ",
            "맥동 강도"
        ),
        .init(
            "Choose light orb image",
            "选择浅色圆球图像",
            "Lightのオーブ画像を選択",
            "Light 오브 이미지 선택"
        ),
        .init(
            "Choose dark orb image",
            "选择深色圆球图像",
            "Darkのオーブ画像を選択",
            "Dark 오브 이미지 선택"
        ),
        .init(
            "{0} orb image set",
            "已设置{0}圆球图像",
            "{0}のオーブ画像を設定しました",
            "{0} 오브 이미지 설정됨"
        ),
        .init(
            "Adjust orb image focal point",
            "调整圆球图像焦点",
            "オーブ画像のフォーカルポイントを調整",
            "오브 이미지 초점 조정"
        ),
        .init(
            "Orb image opacity",
            "圆球图像不透明度",
            "オーブ画像の不透明度",
            "오브 이미지 불투명도"
        ),
        .init(
            "Orb image blur",
            "圆球图像模糊",
            "オーブ画像のぼかし",
            "오브 이미지 흐림"
        ),
        .init(
            "Orb image inset",
            "圆球图像内缩",
            "オーブ画像の内側余白",
            "오브 이미지 안쪽 여백"
        ),
        .init(
            "Test speech intensity",
            "测试说话强度",
            "発話強度をテスト",
            "말하기 강도 테스트"
        ),
        .init(
            "Talking mouth frames",
            "说话嘴型",
            "発話用の口形",
            "말하기 입 모양"
        ),
        .init(
            "Add images",
            "添加多张图像",
            "画像を追加",
            "이미지 추가"
        ),
        .init(
            "1 · Closed",
            "1 · 闭嘴",
            "1・閉じた口",
            "1 · 닫힌 입"
        ),
        .init(
            "Mouth sensitivity",
            "嘴型灵敏度",
            "口形の感度",
            "입 모양 감도"
        ),
        .init(
            "Choose mouth images (least to most open)",
            "选择嘴型图像（由小到大）",
            "口形画像を選択（小さい順）",
            "입 모양 이미지 선택(작게 열린 순서부터)"
        ),
        .init(
            "Add mouth images",
            "添加嘴型图像",
            "口形画像を追加",
            "입 모양 이미지 추가"
        ),
        .init(
            "Add mouth image",
            "添加嘴型图像",
            "口形画像を追加",
            "입 모양 이미지 추가"
        ),
        .init(
            "Remove mouth image",
            "移除嘴型图像",
            "口形画像を削除",
            "입 모양 이미지 제거"
        ),
        .init(
            "Reorder mouth images",
            "调整嘴型顺序",
            "口形画像の順序を変更",
            "입 모양 이미지 순서 변경"
        ),
        .init(
            "Import 2×2 sheet",
            "导入 2×2 嘴型图",
            "2×2シートを読み込む",
            "2×2 시트 가져오기"
        ),
        .init("closed", "闭嘴", "閉じた口", "닫힌 입"),
        .init(
            "Frame 1 is closed. Order the rest from least to most open; Voice opens quickly, closes smoothly, and directly selects the nearest pose.",
            "第 1 张是闭嘴，其余按嘴巴由小到大排列；Voice 会快速张嘴、平滑闭嘴并直接切换到最接近的嘴型。",
            "1枚目は閉じた口です。残りは開きの小さい順に並べます。Voiceは素早く開き、滑らかに閉じ、最も近い口形へ直接切り替えます。",
            "1번은 닫힌 입입니다. 나머지는 적게 열린 순서부터 배치하세요. Voice가 빠르게 열고 부드럽게 닫으며 가장 가까운 입 모양으로 바로 전환합니다."
        ),
        .init(
            "Set speech intensity to 0 to preview idle sway and blinking.",
            "将说话强度设为 0，即可预览待机摇晃和眨眼。",
            "発話強度を0にすると、待機中の揺れとまばたきをプレビューできます。",
            "말하기 강도를 0으로 설정하면 대기 흔들림과 눈 깜빡임을 미리 볼 수 있습니다."
        ),
        .init(
            "Idle animation",
            "待机动画",
            "待機アニメーション",
            "대기 애니메이션"
        ),
        .init(
            "Gently sways the portrait during silence and smoothly stops when speech begins.",
            "静音时让人物轻微摇晃，开始说话时平滑停止。",
            "無音時に人物をわずかに揺らし、発話が始まると滑らかに停止します。",
            "말이 없을 때 인물을 살짝 흔들고 말하기가 시작되면 부드럽게 멈춥니다."
        ),
        .init(
            "Enable idle sway",
            "启用待机摇晃",
            "待機中の揺れを有効にする",
            "대기 흔들림 사용"
        ),
        .init(
            "Sway strength",
            "摇晃幅度",
            "揺れの強さ",
            "흔들림 강도"
        ),
        .init(
            "Sway period",
            "摇晃周期",
            "揺れの周期",
            "흔들림 주기"
        ),
        .init(
            "Closed-eye image",
            "闭眼图片",
            "閉じた目の画像",
            "눈 감은 이미지"
        ),
        .init(
            "Choose a matching closed-eye portrait with the same framing as the closed-mouth image.",
            "选择与闭嘴图片构图一致、仅闭上眼睛的人物图片。",
            "閉じた口の画像と同じ構図で、目だけを閉じた人物画像を選択してください。",
            "입을 다문 이미지와 구도가 같고 눈만 감은 인물 이미지를 선택하세요."
        ),
        .init(
            "Average blink interval",
            "平均眨眼间隔",
            "平均まばたき間隔",
            "평균 눈 깜빡임 간격"
        ),
        .init(
            "Blink duration",
            "眨眼时间",
            "まばたき時間",
            "눈 깜빡임 시간"
        ),
        .init(
            "Choose closed-eye image",
            "选择闭眼图片",
            "閉じた目の画像を選択",
            "눈 감은 이미지 선택"
        ),
        .init(
            "Set closed-eye image",
            "设置闭眼图片",
            "閉じた目の画像を設定",
            "눈 감은 이미지 설정"
        ),
        .init(
            "Clear closed-eye image",
            "清除闭眼图片",
            "閉じた目の画像を消去",
            "눈 감은 이미지 지우기"
        ),
        .init(
            "Import 3×3 sheet",
            "导入 3×3 嘴型图",
            "3×3シートを読み込む",
            "3×3 시트 가져오기"
        ),
        .init(
            "Choose a {0} mouth sprite sheet",
            "选择 {0} 嘴型图",
            "{0}口形スプライトシートを選択",
            "{0} 입 모양 스프라이트 시트 선택"
        ),
        .init(
            "Import {0} mouth sprite sheet",
            "导入 {0} 嘴型图",
            "{0}口形スプライトシートを読み込む",
            "{0} 입 모양 스프라이트 시트 가져오기"
        ),
        .init(
            "Imported {0} mouth frames from left to right, top to bottom.",
            "已按从左到右、从上到下导入 {0} 个嘴型。",
            "左から右、上から下の順に{0}個の口形を読み込みました。",
            "왼쪽에서 오른쪽, 위에서 아래 순서로 입 모양 {0}개를 가져왔습니다."
        ),
        .init(
            "You can use up to nine mouth images, including the closed-mouth base image.",
            "嘴型图像最多 9 张（包含闭嘴基准图）。",
            "閉じた口の基準画像を含め、口形画像は最大9枚まで使用できます。",
            "닫힌 입 기준 이미지를 포함해 입 모양 이미지는 최대 9장까지 사용할 수 있습니다."
        ),
        .init(
            "“{0}” could not be decoded or split into a 2×2 or 3×3 mouth sprite sheet.",
            "无法解码“{0}”或将其切割成 2×2／3×3 嘴型图。",
            "「{0}」をデコード、または2×2／3×3口形スプライトシートに分割できませんでした。",
            "“{0}”을(를) 디코딩하거나 2×2 또는 3×3 입 모양 스프라이트 시트로 분할할 수 없습니다."
        ),
        .init("Mouth attack", "张嘴速度", "口を開く速度", "입 열기 속도"),
        .init("Mouth release", "闭嘴速度", "口を閉じる速度", "입 닫기 속도"),
        .init("Noise gate", "静音阈值", "ノイズゲート", "노이즈 게이트"),
        .init(
            "Mouth response curve",
            "嘴型响应曲线",
            "口形レスポンス曲線",
            "입 모양 반응 곡선"
        ),
        .init(
            "Midnight",
            "午夜",
            "ミッドナイト",
            "미드나이트"
        ),
        .init(
            "Paper",
            "纸张",
            "ペーパー",
            "종이"
        ),
        .init(
            "High Contrast",
            "高对比",
            "ハイコントラスト",
            "고대비"
        ),
        .init(
            "A deep blue-black theme with a cool cyan accent.",
            "深蓝黑底搭配冷调青色强调色的主题。",
            "深いブルーブラックにクールなシアンのアクセントを組み合わせたテーマです。",
            "깊은 청흑색 바탕에 차가운 시안 강조색을 더한 테마입니다."
        ),
        .init(
            "A warm, low-glare light theme inspired by natural paper.",
            "以天然纸张为灵感的温暖、低眩光浅色主题。",
            "自然な紙をイメージした、暖かくまぶしさを抑えたライトテーマです。",
            "천연 종이에서 영감을 받은 따뜻하고 눈부심이 적은 라이트 테마입니다."
        ),
        .init(
            "Maximum contrast with strong focus and selection indicators.",
            "通过清晰的焦点与选择指示提供最高对比度。",
            "明確なフォーカスと選択表示で最大限のコントラストを提供します。",
            "뚜렷한 포커스와 선택 표시로 최대 대비를 제공합니다."
        ),
        .init("open", "张嘴", "開いた口", "열린 입")
    ]
}
