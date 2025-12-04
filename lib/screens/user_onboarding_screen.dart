// lib/screens/user_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../home.dart'; // ⭐️ 추가: 홈 화면으로 이동하기 위해 import

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  // 폼 필드 상태
  final _formKey = GlobalKey<FormState>();
  double _height = 170.0; // 키 (cm)
  double _weight = 65.0;  // 몸무게 (kg)
  int _age = 25;          // 나이
  String _gender = 'MALE'; // 성별: MALE, FEMALE
  bool _hasCaffeine = false; // 카페인 유무
  bool _hasSmoke = false;    // 흡연 유무
  final List<String> _selectedHabits = []; // 수면 습관 (복수 선택)
  String _goal = '';             // 성취 목표

  // 수면 습관 옵션 (사진을 대체하는 텍스트/아이콘)
  final List<Map<String, dynamic>> _habitOptions = [
    {'name': '늦게 잠듦', 'icon': Icons.nights_stay, 'value': 'LateSleeper'},
    {'name': '수면 중 앰', 'icon': Icons.snooze, 'value': 'WakesUp'},
    {'name': '코골이', 'icon': Icons.volume_up, 'value': 'Snoring'},
    {'name': '규칙적 취침', 'icon': Icons.access_time, 'value': 'Regular'},
    {'name': '짧은 수면 시간', 'icon': Icons.hourglass_bottom, 'value': 'ShortSleep'},
  ];

  // 사용자 정보 저장 및 다음 단계로 이동
  void _saveProfile(User user) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await Provider.of<FirestoreService>(context, listen: false).saveUserProfile(
          uid: user.uid,
          height: _height,
          weight: _weight,
          age: _age,
          gender: _gender,
          hasCaffeine: _hasCaffeine,
          hasSmoke: _hasSmoke,
          sleepHabits: _selectedHabits,
          goal: _goal,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('정보 입력이 완료되었습니다!')),
          );
          
          // ⭐️ FIX: 정보 저장 성공 후, 홈 화면으로 이동 (pushReplacement를 사용하여 뒤로 가기 버튼이 작동하지 않도록 함)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('정보 저장 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text("사용자 인증 정보가 없습니다.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('기본 정보 입력', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E0C42),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. 기본 수치 정보 (키, 몸무게, 나이)
              _buildSectionTitle('기본 신체 정보'),
              _buildSliderInput('키 (cm)', _height, 140.0, 210.0, (val) => setState(() => _height = val), _height.round().toString()),
              _buildSliderInput('몸무게 (kg)', _weight, 30.0, 150.0, (val) => setState(() => _weight = val), _weight.round().toString()),
              _buildAgeInput(),
              
              const SizedBox(height: 30),
              
              // 2. 성별 선택
              _buildSectionTitle('성별'),
              _buildGenderSelector(),
              
              const SizedBox(height: 30),
              
              // 3. 라이프스타일 유무 (카페인, 흡연)
              _buildSectionTitle('라이프스타일'),
              _buildToggleInput('카페인 섭취', _hasCaffeine, (val) => setState(() => _hasCaffeine = val)),
              _buildToggleInput('흡연 유무', _hasSmoke, (val) => setState(() => _hasSmoke = val)),

              const SizedBox(height: 30),

              // 4. 수면 습관 (복수 체크)
              _buildSectionTitle('수면 습관 (복수 선택)'),
              _buildHabitSelector(),

              const SizedBox(height: 30),

              // 5. 성취 목표 (텍스트 입력)
              _buildSectionTitle('이 앱을 통한 성취 목표'),
              TextFormField(
                onSaved: (value) => _goal = value ?? '',
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '예: 매일 7시간 이상 숙면하고 싶습니다.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                ),
                validator: (value) => (value == null || value.isEmpty) ? '목표를 입력해주세요.' : null,
              ),

              const SizedBox(height: 40),

              // 6. 가입 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _saveProfile(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A4EC9), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text('가입 완료 및 시작하기', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌더 함수 ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E0C42),
        ),
      ),
    );
  }

  Widget _buildSliderInput(String label, double value, double min, double max, ValueChanged<double> onChanged, String displayValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: displayValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF7A4EC9),
            inactiveColor: const Color(0xFFE5E0F0),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('나이', style: TextStyle(fontSize: 16, color: Colors.black87)),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: _age.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                suffixText: '세',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
              onChanged: (val) {
                if (int.tryParse(val) != null) {
                  _age = int.parse(val);
                }
              },
              validator: (value) => (value == null || int.tryParse(value) == null) ? '필수' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderButton('MALE', '남성', Icons.male),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildGenderButton('FEMALE', '여성', Icons.female),
        ),
      ],
    );
  }

  Widget _buildGenderButton(String value, String label, IconData icon) {
    final bool isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7A4EC9) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E0C42) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleInput(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF7A4EC9),
              inactiveThumbColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHabitSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _habitOptions.length,
      itemBuilder: (context, index) {
        final option = _habitOptions[index];
        final isSelected = _selectedHabits.contains(option['value']);
        
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedHabits.remove(option['value']);
              } else {
                _selectedHabits.add(option['value']);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E0C42) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF7A4EC9) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option['icon'],
                  size: 30,
                  color: isSelected ? Colors.white : const Color(0xFF1E0C42),
                ),
                const SizedBox(height: 8),
                Text(
                  option['name']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}