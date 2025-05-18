import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_screening/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late User? _user;
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _user = _authService.currentUser;
      
      if (_user != null) {
        // Get user data from Firestore
        final docSnapshot = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (docSnapshot.exists) {
          setState(() {
            _userData = docSnapshot.data() ?? {};
            _nameController.text = _userData['name'] ?? _user!.displayName ?? '';
            _phoneController.text = _userData['phone'] ?? '';
            _companyController.text = _userData['company'] ?? '';
            _positionController.text = _userData['position'] ?? '';
          });
        } else {
          // If user document doesn't exist, initialize with auth data
          _nameController.text = _user!.displayName ?? '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_user != null) {
        // Update display name in Firebase Auth
        await _user!.updateDisplayName(_nameController.text);
        
        // Update user data in Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'name': _nameController.text,
          'email': _user!.email,
          'phone': _phoneController.text,
          'company': _companyController.text,
          'position': _positionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _isEditing = false;
          _userData = {
            'name': _nameController.text,
            'email': _user!.email,
            'phone': _phoneController.text,
            'company': _companyController.text,
            'position': _positionController.text,
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset form fields to original values
                  _nameController.text = _userData['name'] ?? _user?.displayName ?? '';
                  _phoneController.text = _userData['phone'] ?? '';
                  _companyController.text = _userData['company'] ?? '';
                  _positionController.text = _userData['position'] ?? '';
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.indigo.shade800,
                        Colors.indigo.shade600,
                        Colors.indigo.shade400,
                        Colors.indigo.shade200,
                      ],
                    ),
                  ),
                ),
                
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        
                        // Profile avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.indigo.shade300,
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // User email
                        Text(
                          _user?.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Profile information card
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isEditing
                              ? _buildEditForm()
                              : _buildProfileInfo(),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Save button (only shown when editing)
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _saveUserData,
                              icon: Icon(Icons.save),
                              label: Text(
                                'Save Profile',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildInfoRow(Icons.person, 'Name', _userData['name'] ?? _user?.displayName ?? 'Not set'),
        Divider(height: 30),
        _buildInfoRow(Icons.phone, 'Phone', _userData['phone'] ?? 'Not set'),
        Divider(height: 30),
        _buildInfoRow(Icons.business, 'Company', _userData['company'] ?? 'Not set'),
        Divider(height: 30),
        _buildInfoRow(Icons.work, 'Position', _userData['position'] ?? 'Not set'),
      ],
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.indigo),
        ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person, color: Colors.indigo),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone, color: Colors.indigo),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _companyController,
            decoration: InputDecoration(
              labelText: 'Company',
              prefixIcon: Icon(Icons.business, color: Colors.indigo),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _positionController,
            decoration: InputDecoration(
              labelText: 'Position',
              prefixIcon: Icon(Icons.work, color: Colors.indigo),
            ),
          ),
        ],
      ),
    );
  }
}
