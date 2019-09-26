//
//  UIKitRACExtensions.swift
//  TestProject
//
//  Created by robert john alkuino on 25/09/2019.
//  Copyright © 2019 robert john alkuino. All rights reserved.
//

import UIKit
import ReactiveSwift

struct AssociationKey {
    static var hidden: UInt8 = 1
    static var alpha: UInt8 = 2
    static var text: UInt8 = 3
    static var enabled: UInt8 = 4
    static var textColor: UInt8 = 5
    static var userInteractionEnabled: UInt8 = 6
    static var image: UInt8 = 7
    static var title: UInt8 = 8
    static var placeholder: UInt8 = 9
    static var animating: UInt8 = 10
    static var backgroundColor: UInt8 = 11
    static var buttonTitle: UInt8 = 12
    static var buttonTitleColor: UInt8 = 13
    static var imageUrl: UInt8 = 14
    static var status: UInt8 = 15
    static var loading: UInt8 = 16
}

enum objc_AssociationPolicy : UInt {
    case OBJC_ASSOCIATION_ASSIGN
    case OBJC_ASSOCIATION_RETAIN_NONATOMIC
    case OBJC_ASSOCIATION_COPY_NONATOMIC
    case OBJC_ASSOCIATION_RETAIN
    case OBJC_ASSOCIATION_COPY
}

// lazily creates a gettable associated property via the given factory
func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafeRawPointer, factory: ()->T) -> T {
    return objc_getAssociatedObject(host, key) as? T ?? {
        let associatedProperty = factory()
        objc_setAssociatedObject(host, key, associatedProperty, .OBJC_ASSOCIATION_RETAIN)
        return associatedProperty
        }()
}

func lazyMutableProperty<T>(host: AnyObject, key: UnsafeRawPointer, setter: @escaping (T) -> (), getter: () -> T) -> MutableProperty<T> {
    return lazyAssociatedProperty(host: host, key: key) {
        let property = MutableProperty<T>(getter())
        property.producer.startWithValues { setter($0) }
        return property
    }
}


//extension LineTextField {
//    
//    var rac_status: MutableProperty<LineTextField.Status> {
//        return lazyMutableProperty(host: self, key: &AssociationKey.status, setter: { self.status = $0 }, getter: { self.status })
//    }
//
//}
//
//extension ActionButton {
//
//    var rac_loading: MutableProperty<Bool> {
//        return lazyMutableProperty(host: self, key: &AssociationKey.loading, setter: { self.isLoading = $0 }, getter: { self.isLoading })
//    }
//
//}

extension UIButton {
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(host: self, key: &AssociationKey.enabled, setter: { self.isEnabled = $0 }, getter: { self.isEnabled })
    }
    
    public var rac_backgroundColor: MutableProperty<UIColor?> {
        return lazyMutableProperty(host: self, key: &AssociationKey.backgroundColor, setter: { self.backgroundColor = $0 }, getter: { self.backgroundColor })
    }
    
    public var rac_titleColor: MutableProperty<UIColor?> {
        return lazyAssociatedProperty(host: self, key: &AssociationKey.buttonTitleColor) {
            let property = MutableProperty<UIColor?>(nil)
            property.producer.startWithValues { self.setTitleColor($0, for: .normal) }
            return property
        }
    }
    
    public var rac_title: MutableProperty<String> {
        return lazyAssociatedProperty(host: self, key: &AssociationKey.buttonTitle) {
            let property = MutableProperty<String>("")
            property.producer.startWithValues { self.setTitle($0, for: .normal) }
            return property
        }
    }
}

extension UIView {
    public var rac_alpha: MutableProperty<CGFloat> {
        return lazyMutableProperty(host: self, key: &AssociationKey.alpha, setter: { self.alpha = $0 }, getter: { self.alpha })
    }
    
    public var rac_hidden: MutableProperty<Bool> {
        return lazyMutableProperty(host: self, key: &AssociationKey.hidden, setter: { self.isHidden = $0 }, getter: { self.isHidden })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(host: self, key: &AssociationKey.userInteractionEnabled, setter: { self.isUserInteractionEnabled = $0 }, getter: { self.isUserInteractionEnabled })
    }
}

extension UINavigationItem {
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(host: self, key: &AssociationKey.title, setter: { self.title = $0 }, getter: { self.title ?? "" })
    }
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(host: self, key: &AssociationKey.text, setter: { self.text = $0 }, getter: { self.text ?? "" })
    }
    
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(host: self, key: &AssociationKey.enabled, setter: { self.isEnabled = $0 }, getter: { self.isEnabled })
    }
    
    public var rac_textColor: MutableProperty<UIColor> {
        return lazyMutableProperty(host: self, key: &AssociationKey.textColor, setter: { self.textColor = $0 }, getter: { self.textColor })
    }
}

extension UITextField {
    public var rac_text: MutableProperty<String> {
        return lazyAssociatedProperty(host: self, key: &AssociationKey.text) {
            self.addTarget(self, action: #selector(changed), for: UIControl.Event.editingChanged)
            
            let property = MutableProperty<String>(self.text ?? "")
            property.producer.startWithValues{ self.text = $0 }
            return property
        }
    }
    
    @objc func changed() {
        rac_text.value = self.text ?? ""
    }
    
    public var rac_textColor: MutableProperty<UIColor?> {
        return lazyMutableProperty(host: self, key: &AssociationKey.textColor, setter: { self.textColor = $0 }, getter: { self.textColor })
    }
    
    public var rac_placeholder: MutableProperty<String?> {
        return lazyMutableProperty(host: self, key: &AssociationKey.placeholder, setter: { self.placeholder = $0 }, getter: { self.placeholder })
    }
}

extension UITextView {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(host: self, key: &AssociationKey.text, setter: { self.text = $0 }, getter: { self.text })
    }
}

extension UIActivityIndicatorView {
    public var rac_animating: MutableProperty<Bool> {
        return lazyAssociatedProperty(host: self, key: &AssociationKey.animating) {
            let property = MutableProperty<Bool>(false)
            property.producer.startWithValues { $0 ? self.startAnimating() : self.stopAnimating() }
            return property
        }
    }
}


