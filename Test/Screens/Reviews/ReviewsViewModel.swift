import UIKit

class CountCell: UITableViewCell {

    private let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(countText: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.created,
            .foregroundColor: UIColor.created
            ]
        let attributedString = NSAttributedString(string: countText, attributes: attributes)
        countLabel.attributedText = attributedString
    }
}
/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            state.items += reviews.items.map(makeReviewItem)
            state.offset += state.limit
            state.count = reviews.count
            state.shouldLoad = state.offset < reviews.count
            if state.shouldLoad == false, !state.items.contains(where: { $0 is CountCellConfig }) {
                state.items.append(CountCellConfig(countText: "Всего отзывов: \(reviews.count)"))
            }
        } catch {
            state.shouldLoad = true        }
        onStateChange?(state)
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let reviewText: NSAttributedString
        if review.text.isEmpty {
            reviewText = NSAttributedString(string: "No review text", attributes: [.font: UIFont.text])
        } else {
            reviewText = review.text.attributed(font: .text)
        }

        let created = review.created.attributed(font: .created, color: .created)
        let fullName = "\(review.first_name ?? "") \(review.last_name ?? "")"

        let avatarImage = UIImage(named: "l5w5aIHioYc")
        
        let ratingRenderer = RatingRenderer()
        let ratingImage = ratingRenderer.ratingImage(review.rating)
        return ReviewItem(
            reviewText: reviewText, fullName: fullName.attributed(font: .boldSystemFont(ofSize: 16)),
            created: created,
            avatarImage: avatarImage,
            onTapShowMore: showMoreReview,
            rating: review.rating
        )
    }
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        
        // Проверка на CountCellConfig и создание ячейки с количеством отзывов
        if let countCellConfig = config as? CountCellConfig {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CountCellConfig", for: indexPath) as? CountCell {
                cell.configure(countText: countCellConfig.countText)
                return cell
            }
        }
        
        // Для других типов ячеек, например, ReviewCell
        if let reviewCellConfig = config as? ReviewCellConfig {
            if let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCellConfig.reuseId, for: indexPath) as? ReviewCell {
                reviewCellConfig.update(cell: cell)
                return cell
            }
        }
        
        // Возвращаем пустую ячейку, если ничего не подошло
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
