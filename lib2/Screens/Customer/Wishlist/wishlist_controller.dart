// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../Models/Users.dart';
// import '../../Models/wishlist_model.dart';
//
//
// class WishlistController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Get current user ID
//   Future<String?> _getCurrentUserId() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? email = prefs.getString('Email');
//       if (email != null) {
//         UsersModel? user = await UsersRepository.getUserByEmail(email);
//         return user?.id;
//       }
//       return null;
//     } catch (e) {
//       print('❌ Error getting current user ID: $e');
//       return null;
//     }
//   }
//
//   // Toggle wishlist item
//   Future<bool> toggleWishlistItem(String productId) async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) {
//         print('❌ User not logged in');
//         return false;
//       }
//
//       // Check if item already exists in wishlist
//       QuerySnapshot existingItem = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .where('productId', isEqualTo: productId)
//           .get();
//
//       if (existingItem.docs.isNotEmpty) {
//         // Item exists, toggle isFavorite
//         DocumentSnapshot doc = existingItem.docs.first;
//         WishlistModel existingWishlist = WishlistModel.fromSnapshot(doc);
//
//         if (existingWishlist.isFavorite) {
//           // Currently favorite, make it unfavorite
//           if (existingWishlist.notes == null || existingWishlist.notes!.isEmpty) {
//             // Delete the document if notes is null/empty
//             await doc.reference.delete();
//             print('✅ Wishlist item deleted');
//           } else {
//             // Update isFavorite to false
//             await doc.reference.update({
//               'isFavorite': false,
//               'addedAt': FieldValue.serverTimestamp(),
//             });
//             print('✅ Wishlist item updated to unfavorite');
//           }
//           return false; // Removed from favorites
//         } else {
//           // Currently not favorite, make it favorite
//           await doc.reference.update({
//             'isFavorite': true,
//             'addedAt': FieldValue.serverTimestamp(),
//           });
//           print('✅ Wishlist item updated to favorite');
//           return true; // Added to favorites
//         }
//       } else {
//         // Item doesn't exist, create new wishlist item
//         WishlistModel newWishlistItem = WishlistModel(
//           userId: userId,
//           productId: productId,
//           isFavorite: true,
//           notes: null,
//         );
//
//         await _firestore.collection('WishList').add(newWishlistItem.toMap());
//         print('✅ New wishlist item created');
//         return true; // Added to favorites
//       }
//     } catch (e) {
//       print('❌ Error toggling wishlist item: $e');
//       return false;
//     }
//   }
//
//   // Check if product is in wishlist
//   Future<bool> isProductInWishlist(String productId) async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) return false;
//
//       QuerySnapshot snapshot = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .where('productId', isEqualTo: productId)
//           .where('isFavorite', isEqualTo: true)
//           .get();
//
//       return snapshot.docs.isNotEmpty;
//     } catch (e) {
//       print('❌ Error checking wishlist status: $e');
//       return false;
//     }
//   }
//
//   // Get all wishlist items for current user
//   Future<List<WishlistModel>> getWishlistItems() async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) return [];
//
//       QuerySnapshot snapshot = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .where('isFavorite', isEqualTo: true)
//           .orderBy('addedAt', descending: true)
//           .get();
//
//       return WishlistModel.fromQuerySnapshot(snapshot);
//     } catch (e) {
//       print('❌ Error getting wishlist items: $e');
//       return [];
//     }
//   }
//
//   // Update notes for wishlist item
//   Future<bool> updateWishlistNotes(String productId, String notes) async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) return false;
//
//       QuerySnapshot snapshot = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .where('productId', isEqualTo: productId)
//           .get();
//
//       if (snapshot.docs.isNotEmpty) {
//         await snapshot.docs.first.reference.update({
//           'notes': notes.trim().isEmpty ? null : notes.trim(),
//           'addedAt': FieldValue.serverTimestamp(),
//         });
//         print('✅ Wishlist notes updated');
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print('❌ Error updating wishlist notes: $e');
//       return false;
//     }
//   }
//
//   // Remove item from wishlist
//   Future<bool> removeFromWishlist(String productId) async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) return false;
//
//       QuerySnapshot snapshot = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .where('productId', isEqualTo: productId)
//           .get();
//
//       if (snapshot.docs.isNotEmpty) {
//         await snapshot.docs.first.reference.delete();
//         print('✅ Item removed from wishlist');
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print('❌ Error removing from wishlist: $e');
//       return false;
//     }
//   }
//
//   // Get wishlist count
//   Future<int> getWishlistCount() async {
//     try {
//       List<WishlistModel> items = await getWishlistItems();
//       return items.length;
//     } catch (e) {
//       print('❌ Error getting wishlist count: $e');
//       return 0;
//     }
//   }
//
//   // Clear entire wishlist
//   Future<bool> clearWishlist() async {
//     try {
//       String? userId = await _getCurrentUserId();
//       if (userId == null) return false;
//
//       QuerySnapshot snapshot = await _firestore
//           .collection('WishList')
//           .where('userId', isEqualTo: userId)
//           .get();
//
//       WriteBatch batch = _firestore.batch();
//       for (DocumentSnapshot doc in snapshot.docs) {
//         batch.delete(doc.reference);
//       }
//       await batch.commit();
//
//       print('✅ Wishlist cleared successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error clearing wishlist: $e');
//       return false;
//     }
//   }
// }




import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/Users.dart';
import '../../Models/wishlist_model.dart';


class WishlistController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      if (email != null && email.isNotEmpty) {
        UsersModel? user = await UsersRepository.getUserByEmail(email);
        return user?.id;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      return email != null && email.isNotEmpty;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // Toggle wishlist item
  Future<bool> toggleWishlistItem(String productId) async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return false;
      }

      print('🔄 Toggling wishlist for product: $productId, user: $userId');

      // Check if item already exists in wishlist
      QuerySnapshot existingItem = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Item exists, check current status
        DocumentSnapshot doc = existingItem.docs.first;
        WishlistModel existingWishlist = WishlistModel.fromSnapshot(doc);

        print('📋 Existing wishlist item found. Current isFavorite: ${existingWishlist.isFavorite}');

        if (existingWishlist.isFavorite) {
          // Currently favorite, make it unfavorite or delete
          if (existingWishlist.notes == null || existingWishlist.notes!.trim().isEmpty) {
            // Delete the document if notes is null/empty
            await doc.reference.delete();
            print('✅ Wishlist item deleted (no notes)');
          } else {
            // Update isFavorite to false
            await doc.reference.update({
              'isFavorite': false,
              'addedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Wishlist item updated to unfavorite (has notes)');
          }
          return false; // Removed from favorites
        } else {
          // Currently not favorite, make it favorite
          await doc.reference.update({
            'isFavorite': true,
            'addedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Wishlist item updated to favorite');
          return true; // Added to favorites
        }
      } else {
        // Item doesn't exist, create new wishlist item
        WishlistModel newWishlistItem = WishlistModel(
          userId: userId,
          productId: productId,
          isFavorite: true,
          notes: null,
        );

        await _firestore.collection('WishList').add(newWishlistItem.toMap());
        print('✅ New wishlist item created');
        return true; // Added to favorites
      }
    } catch (e) {
      print('❌ Error toggling wishlist item: $e');
      return false;
    }
  }

  // Check if product is in wishlist
  Future<bool> isProductInWishlist(String productId) async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) return false;

      QuerySnapshot snapshot = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('isFavorite', isEqualTo: true)
          .get();

      bool inWishlist = snapshot.docs.isNotEmpty;
      print('🔍 Product $productId in wishlist: $inWishlist');
      return inWishlist;
    } catch (e) {
      print('❌ Error checking wishlist status: $e');
      return false;
    }
  }

  // Get all wishlist items for current user
  Future<List<WishlistModel>> getWishlistItems() async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('addedAt', descending: true)
          .get();

      return WishlistModel.fromQuerySnapshot(snapshot);
    } catch (e) {
      print('❌ Error getting wishlist items: $e');
      return [];
    }
  }

  // Update notes for wishlist item
  Future<bool> updateWishlistNotes(String productId, String notes) async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) return false;

      QuerySnapshot snapshot = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'notes': notes.trim().isEmpty ? null : notes.trim(),
          'addedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Wishlist notes updated');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error updating wishlist notes: $e');
      return false;
    }
  }

  // Remove item from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) return false;

      QuerySnapshot snapshot = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        print('✅ Item removed from wishlist');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  // Get wishlist count
  Future<int> getWishlistCount() async {
    try {
      List<WishlistModel> items = await getWishlistItems();
      return items.length;
    } catch (e) {
      print('❌ Error getting wishlist count: $e');
      return 0;
    }
  }

  // Clear entire wishlist
  Future<bool> clearWishlist() async {
    try {
      String? userId = await _getCurrentUserId();
      if (userId == null) return false;

      QuerySnapshot snapshot = await _firestore
          .collection('WishList')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Wishlist cleared successfully');
      return true;
    } catch (e) {
      print('❌ Error clearing wishlist: $e');
      return false;
    }
  }
}