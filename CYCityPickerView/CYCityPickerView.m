//
//  CYCityPickerView.m
//  CYCityPickerViewDemo
//
//  Created by Cyrill on 2016/12/8.
//  Copyright © 2016年 Cyrill. All rights reserved.
//

#import "CYCityPickerView.h"

/** 列数 */
#define CY_CITY_PICKER_COMPONENTS    3

#define CY_PROVINCE_COMPONENT        0
#define CY_CITY_COMPONENT            1
#define CY_DISCTRCT_COMPONENT        2

#define CY_FIRST_INDEX               0

#define CY_COMPONENT_WIDTH   100 // 每一列的宽度

@interface CYCityPickerView () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, copy, readwrite) NSString *province;
@property (nonatomic, copy, readwrite) NSString *city;
@property (nonatomic, copy, readwrite) NSString *district;

@property (nonatomic, copy) NSDictionary *allCityInfo;
@property (nonatomic, copy) NSArray *provinceArr;/**< 省名称数组*/
@property (nonatomic, copy) NSArray *cityArr;/**< 市名称数组*/
@property (nonatomic, copy) NSArray *districtArr;/**< 区名称数组*/
@property (nonatomic, copy) NSDictionary *currentProvinceDic;
@property (nonatomic, copy) NSDictionary *currentCityDic;

@end

@implementation CYCityPickerView

- (instancetype)init {
    if (self = [super init]) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}


#pragma mark - UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    // 列
    return CY_CITY_PICKER_COMPONENTS;
}

// 该方法返回值决定该控件指定列包含多少个列表项
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case CY_PROVINCE_COMPONENT: return [self.provinceArr count];
        case CY_CITY_COMPONENT:     return [self.cityArr count];
        case CY_DISCTRCT_COMPONENT: return [self.districtArr count];
    }
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *titleLabel = (UILabel *)view;
    if (!titleLabel) {
        titleLabel = [self labelForPickerView];
    }
    titleLabel.text = [self titleForComponent:component row:row];
    return titleLabel;
}


// 选择指定列、指定列表项时调用该方法
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == CY_PROVINCE_COMPONENT) {
        NSDictionary *provinceDic = [self provinceDicAtIndex:row];
        NSArray *cityNames = [self cityNamesInProvinceDic:provinceDic];
        self.currentProvinceDic = provinceDic;
        self.cityArr = cityNames;
        
        NSDictionary *cityDic = [self provinceDic:provinceDic cityDicAtIndex:CY_FIRST_INDEX];
        NSArray *districtNames = [self districtArrayInCityDic:cityDic];
        self.districtArr = districtNames;
        
        self.province = [self provinceNameWithPrivinceDic:provinceDic];
        self.city = [[self cityNamesInProvinceDic:provinceDic] firstObject];
        self.district = [self.districtArr firstObject];
        
        [pickerView selectRow:CY_FIRST_INDEX inComponent:CY_CITY_COMPONENT animated:NO];
        [pickerView selectRow:CY_FIRST_INDEX inComponent:CY_DISCTRCT_COMPONENT animated:NO];
        
        [pickerView reloadAllComponents];
        
    } else if (component == CY_CITY_COMPONENT) {
        NSDictionary *cityDic = [self provinceDic:self.currentProvinceDic cityDicAtIndex:row];
        self.currentCityDic = cityDic;
        self.districtArr = [self districtArrayInCityDic:cityDic];
        
        self.province = [self provinceNameWithPrivinceDic:self.currentProvinceDic];
        self.city = [self cityNameWithCityDic:cityDic];
        self.district = [self.districtArr firstObject];
        
        [pickerView selectRow:CY_FIRST_INDEX inComponent:CY_DISCTRCT_COMPONENT animated:NO];
        [pickerView reloadComponent:CY_DISCTRCT_COMPONENT];
        
    } else if (component == CY_DISCTRCT_COMPONENT) {
        self.province = [self provinceNameWithPrivinceDic:self.currentProvinceDic];
        self.city = [self cityNameWithCityDic:self.currentCityDic];
        self.district = [self.districtArr objectAtIndex:row];
    }
    
    if ([self.cityPickerDelegate respondsToSelector:@selector(cityPickerView:finishPickProvince:city:district:)]) {
        [self.cityPickerDelegate cityPickerView:self finishPickProvince:self.province city:self.city district:self.district];
    }
    
}

// 指定列的宽度
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    // 宽度
    return CY_COMPONENT_WIDTH;
}


#pragma mark - Private

- (UILabel *)labelForPickerView
{
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor colorWithRed:85/255 green:85/255 blue:85/255 alpha:1];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (NSString *)titleForComponent:(NSInteger)component row:(NSInteger)row {
    switch (component)
    {
        case CY_PROVINCE_COMPONENT: return [self.provinceArr objectAtIndex:row];
        case CY_CITY_COMPONENT:     return [self.cityArr objectAtIndex:row];
        case CY_DISCTRCT_COMPONENT: return [self.districtArr objectAtIndex:row];
    }
    return @"";
}

/**
 获取省级字典

 @param index index
 @return 省级字典
 */
- (NSDictionary *)provinceDicAtIndex:(NSUInteger)index {
    return [self.allCityInfo objectForKey:[@(index) stringValue]];
}

/**
 返回省级字典的名字

 @param provinceDic 省级字典
 @return NSString
 */
- (NSString *)provinceNameWithPrivinceDic:(NSDictionary *)provinceDic {
    return [[provinceDic allKeys] firstObject];
}

/**
 返回省级字典下面的市名称列表

 @param provinceDic 省级字典
 @return NSMutableArray<NSString>
 */
- (NSMutableArray *)cityNamesInProvinceDic:(NSDictionary *)provinceDic {
    NSMutableArray *temp = [NSMutableArray array];
    for (NSInteger i = 0; i < [[[provinceDic allValues] firstObject] count]; i++) {
        NSDictionary *cityDic = [self provinceDic:provinceDic cityDicAtIndex:i];
        [temp addObject:[self cityNameWithCityDic:cityDic]];
    }
    return temp;
}

/**
 获取省级字典下的市级字典

 @param provinceDic 省级字典
 @param index index
 @return 市级字典
 */
- (NSDictionary *)provinceDic:(NSDictionary *)provinceDic cityDicAtIndex:(NSUInteger)index {
    NSDictionary *cityDicInProvince = [provinceDic objectForKey:[self provinceNameWithPrivinceDic:provinceDic]];
    return [cityDicInProvince objectForKey:[@(index) stringValue]];
}

/**
 *  返回市级字典的市名称
 *
 *  @param cityDic 市级字典
 *
 *  @return NSSting
 */
- (NSString *)cityNameWithCityDic:(NSDictionary *)cityDic {
    return [[cityDic allKeys] firstObject];
}

/**
 *  返回市级字典下的区/县信息
 *
 *  @param cityDic 市级字典
 *
 *  @return NSArray<NSString>
 */
- (NSArray *)districtArrayInCityDic:(NSDictionary *)cityDic {
    return [[cityDic allValues] firstObject];
}

#pragma mark - Getter and Setter
- (NSDictionary *)allCityInfo {
    if (!_allCityInfo) {
        Class selfClass = [self class];
        NSBundle *bundle = [NSBundle bundleForClass:selfClass];
        NSURL *url = [bundle URLForResource:NSStringFromClass(selfClass) withExtension:@"bundle"];
        NSBundle *cityBundle = [NSBundle bundleWithURL:url];
        NSString *path = [cityBundle pathForResource:@"city" ofType:@"plist"];
        
        if (_cy_plistPath && _cy_plistPath.length > 0) {
            path = _cy_plistPath;
        }
        
        _allCityInfo = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    return _allCityInfo;
}

- (NSArray *)provinceArr {
    if (!_provinceArr) {
        NSMutableArray *temp = [NSMutableArray array];
        for (NSInteger i = 0 ; i < [[self.allCityInfo allKeys] count]; i++) {
            NSDictionary *provinceDic = [self provinceDicAtIndex:i];
            [temp addObject:[self provinceNameWithPrivinceDic:provinceDic]];
        }
        _provinceArr = temp;
    }
    return _provinceArr;
}

- (NSArray *)cityArr {
    if (!_cityArr) {
        NSDictionary *provinceDic = [self provinceDicAtIndex:CY_FIRST_INDEX];
        _cityArr = [self cityNamesInProvinceDic:provinceDic];
    }
    return _cityArr;
}

- (NSArray *)districtArr {
    if (!_districtArr) {
        NSDictionary *cityDic = [self provinceDic:[self provinceDicAtIndex:CY_FIRST_INDEX] cityDicAtIndex:CY_FIRST_INDEX];
        _districtArr = [self districtArrayInCityDic:cityDic];
    }
    return _districtArr;
}

- (NSDictionary *)currentProvinceDic {
    if (!_currentProvinceDic) {
        _currentProvinceDic = [self provinceDicAtIndex:CY_FIRST_INDEX];
    }
    return _currentProvinceDic;
}

- (NSDictionary *)currentCityDic {
    if (!_currentCityDic) {
        _currentCityDic = [self provinceDic:self.currentProvinceDic cityDicAtIndex:CY_FIRST_INDEX];
    }
    return _currentCityDic;
}

@end
