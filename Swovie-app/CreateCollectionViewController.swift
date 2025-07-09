import UIKit

protocol CreateCollectionDelegate: AnyObject {
    func didCreateCollection(_ collection: MovieCollection)
}

class CreateCollectionViewController: UIViewController {
    
    weak var delegate: CreateCollectionDelegate?
    
    private let nameTextField = UITextField()
    private var selectedIconName: String = "folder.fill"
    private var selectedColor: UIColor = .systemBlue
    private var iconButtons: [UIButton] = []
    private var selectionBackgroundViews: [UIView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Новая коллекция"
        
        setupForm()
    }
    
    private func setupForm() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Text field
        nameTextField.placeholder = "Название коллекции"
        nameTextField.borderStyle = .roundedRect
        nameTextField.widthAnchor.constraint(equalToConstant: 250).isActive = true
        stack.addArrangedSubview(nameTextField)
        
        // Icon selection
        let iconStack = UIStackView()
        iconStack.axis = .horizontal
        iconStack.spacing = 16

        let icons = ["folder.fill", "film.fill", "star.fill"]
        iconButtons = []
        selectionBackgroundViews = []
        for (index, icon) in icons.enumerated() {
            // Container view for highlight and button
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            // Gray background view for selection highlight
            let highlight = UIView()
            highlight.backgroundColor = UIColor.systemGray5
            highlight.layer.cornerRadius = 12
            highlight.isHidden = true
            highlight.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(highlight)
            // Button
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: icon), for: .normal)
            button.tintColor = selectedColor
            button.tag = index
            button.backgroundColor = .clear
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 0
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.addTarget(self, action: #selector(iconSelected(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)
            // Constraints: highlight fills container, button centered and sized
            NSLayoutConstraint.activate([
                highlight.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                highlight.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                highlight.topAnchor.constraint(equalTo: container.topAnchor),
                highlight.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 40),
                button.heightAnchor.constraint(equalToConstant: 40),
                container.widthAnchor.constraint(equalToConstant: 44),
                container.heightAnchor.constraint(equalToConstant: 44)
            ])
            iconStack.addArrangedSubview(container)
            iconButtons.append(button)
            selectionBackgroundViews.append(highlight)
        }
        // Highlight default selected icon
        updateIconSelection()
        
        stack.addArrangedSubview(iconStack)
        
        // Color selection
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPurple]
        let colorStack = UIStackView()
        colorStack.axis = .horizontal
        colorStack.spacing = 16
        
        for color in colors {
            let colorButton = UIButton(type: .system)
            colorButton.backgroundColor = color
            colorButton.layer.cornerRadius = 15
            colorButton.layer.borderWidth = 2
            colorButton.layer.borderColor = UIColor.clear.cgColor
            colorButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
            colorButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            colorButton.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
            colorStack.addArrangedSubview(colorButton)
            if color == selectedColor {
                colorButton.layer.borderColor = UIColor.label.cgColor
            }
        }
        
        stack.addArrangedSubview(colorStack)
        
        // Save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        saveButton.backgroundColor = selectedColor
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 8
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func updateIconSelection() {
        let icons = ["folder.fill", "film.fill", "star.fill"]
        for (index, button) in iconButtons.enumerated() {
            // Highlight only the selected, hide others
            if selectedIconName == icons[button.tag] {
                button.layer.borderWidth = 2
                button.layer.borderColor = selectedColor.cgColor
                if selectionBackgroundViews.indices.contains(index) {
                    selectionBackgroundViews[index].isHidden = false
                }
            } else {
                button.layer.borderWidth = 0
                button.layer.borderColor = UIColor.clear.cgColor
                if selectionBackgroundViews.indices.contains(index) {
                    selectionBackgroundViews[index].isHidden = true
                }
            }
            button.tintColor = selectedColor
        }
    }
    
    @objc private func iconSelected(_ sender: UIButton) {
        let icons = ["folder.fill", "film.fill", "star.fill"]
        selectedIconName = icons[sender.tag]
        updateIconSelection()
    }
    
    @objc private func colorSelected(_ sender: UIButton) {
        guard let color = sender.backgroundColor else { return }
        selectedColor = color
        
        // Update icon buttons tint and border color
        updateIconSelection()
        
        // Update color buttons border to indicate selection
        if let colorStack = sender.superview as? UIStackView {
            for case let button as UIButton in colorStack.arrangedSubviews {
                button.layer.borderColor = UIColor.clear.cgColor
            }
            sender.layer.borderColor = UIColor.label.cgColor
        }
        
    }
    
    @objc private func saveTapped() {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        let newCollection = MovieCollection(name: name, reviews: [])
        delegate?.didCreateCollection(newCollection)
        dismiss(animated: true)
    }
}
