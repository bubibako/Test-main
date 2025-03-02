import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Текст отзыва.
    let reviewText: NSAttributedString
    
    let fullName: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    
    let avatarImage: UIImage?
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    
    let rating: Int

    let usernameToRatingSpacing: CGFloat = 6.0

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.fullNameLabel.attributedText = fullName
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.avatarImageView.image = avatarImage
        cell.config = self
        
        let ratingImage = RatingRenderer().ratingImage(rating)
        cell.ratingImageView.image = ratingImage
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}
struct CountCellConfig: TableCellConfig {
    static let reuseId = "CountCell"

    let countText: String

    func update(cell: UITableViewCell) {
        cell.textLabel?.text = countText
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cell.selectionStyle = .none
    }

    func height(with size: CGSize) -> CGFloat {
        return 44
    }
}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate let avatarImageView = UIImageView()
    fileprivate let fullNameLabel = UILabel()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    fileprivate let ratingImageView = UIImageView()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        avatarImageView.frame = layout.avatarFrame
        fullNameLabel.frame = layout.fullNameFrame
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        let ratingX = fullNameLabel.frame.origin.x
        let ratingY = fullNameLabel.frame.maxY + 6
        ratingImageView.frame = CGRect(x: ratingX, y: ratingY, width: 80, height: 16)
    }

}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImageView()
        setupFullNameLabel()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupRatingImageView()
        setupRatingImageView()
        guard let config = config else { return }
        let ratingRenderer = RatingRenderer()
        let ratingImage = ratingRenderer.ratingImage(config.rating)
        let ratingImageView = UIImageView(image: ratingImage)
        contentView.addSubview(ratingImageView)
        
        let ratingX = fullNameLabel.frame.origin.x
        let ratingY = fullNameLabel.frame.maxY + 6.0
        ratingImageView.frame = CGRect(x: ratingX, y: ratingY, width: ratingImageView.image?.size.width ?? 0, height: ratingImageView.image?.size.height ?? 0)
    }

    func setupAvatarImageView() {
        contentView.addSubview(avatarImageView)
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
        avatarImageView.image = config?.avatarImage ?? UIImage(named: "l5w5aIHioYc")
    }
    
    func setupFullNameLabel() {
        contentView.addSubview(fullNameLabel)
        fullNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
    }
    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }
    
    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .scaleAspectFit
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
    }
    
    @objc func didTapShowMore() {
        guard let config = config else { return }
        config.onTapShowMore(config.id)
    }

}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {
    
    // MARK: - Размеры
    
    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0
    fileprivate let ratingHeight: CGFloat = 16.0
    fileprivate let ratingSpacing: CGFloat = 6.0
    
    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    // MARK: - Фреймы
    
    private(set) var avatarFrame = CGRect.zero
    private(set) var fullNameFrame = CGRect.zero
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var ratingFrame = CGRect.zero
    
    func calculateRatingrame(maxWidth: CGFloat) {
        let textX = fullNameFrame.origin.x
        let ratingWidth: CGFloat = 80.0
        
        ratingFrame = CGRect(x: textX, y: fullNameFrame.maxY + ratingSpacing, width: ratingWidth, height: ratingHeight)
    }
    
    // MARK: - Отступы
    
    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 8.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0
    
    private let avatarToTextSpacing = 10.0
    
    // MARK: - Расчёт фреймов и высоты ячейки
    
    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        let avatarX = insets.left
        let avatarY = insets.top
        
        avatarFrame = CGRect(origin: CGPoint(x: avatarX, y: avatarY), size: Self.avatarSize)
        
        let textX = avatarFrame.maxX + avatarToTextSpacing
        let textWidth = width - Self.avatarSize.width - avatarToTextSpacing
        
        fullNameFrame = CGRect(
            x: textX, y: avatarY,
            width: textWidth, height: 20
            )
        
        let ratingY = fullNameFrame.maxY + usernameToRatingSpacing
        let ratingFrame = CGRect(
            x: textX, y: ratingY,
            width: textWidth, height: 20
        )
        
        let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
        let actualTextHeight = config.reviewText.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size.height
        let showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
        
        let reviewTextSize = config.reviewText.boundingRect(
            with: CGSize(width: textWidth, height: currentTextHeight),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size

        reviewTextLabelFrame = CGRect(
            origin: CGPoint(x: textX, y: ratingFrame.maxY + ratingToTextSpacing),
            size: reviewTextSize
        )
        
        var maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: textX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + reviewTextToCreatedSpacing // Увеличиваем отступ
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: textX, y: maxY + 6), // Здесь используем maxY для правильного размещения
            size: config.created.boundingRect(
                with: CGSize(width: textWidth, height: 20),
                options: .usesLineFragmentOrigin,
                context: nil
            ).size
        )
        
        return max(avatarFrame.maxY, createdLabelFrame.maxY) + insets.bottom
    }
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
