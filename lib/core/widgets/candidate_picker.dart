import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'player_card.dart';

/// Component D12: CandidatePicker (Frontend Implementation Plan §4.1).
/// Searchable and filterable picker for selecting replacement candidates in Transfer Lab.
class CandidatePicker extends StatefulWidget {
  final List<PlayerCandidate> availableCandidates;
  final int maxBudgetTenths;
  final String? initialPositionFilter;
  final ValueChanged<PlayerCandidate> onCandidateSelected;

  const CandidatePicker({
    super.key,
    required this.availableCandidates,
    required this.maxBudgetTenths,
    this.initialPositionFilter,
    required this.onCandidateSelected,
  });

  @override
  State<CandidatePicker> createState() => _CandidatePickerState();
}

class _CandidatePickerState extends State<CandidatePicker> {
  late String _selectedPosition;
  String _searchQuery = '';
  final String _sortBy = 'xp'; // 'xp' or 'price'

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPositionFilter ?? 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.availableCandidates.where((p) {
      if (p.priceTenths > widget.maxBudgetTenths) return false;
      if (_selectedPosition != 'ALL' && p.position != _selectedPosition) return false;
      if (_searchQuery.isNotEmpty &&
          !p.webName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'xp') {
        return b.xp.compareTo(a.xp);
      } else {
        return a.priceTenths.compareTo(b.priceTenths);
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 16.0),
      decoration: const BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: AppTokens.borderSubtle,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Player',
                style: AppTextStyles.headline.copyWith(
                  color: AppTokens.textPrimary,
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Max: £${(widget.maxBudgetTenths / 10.0).toStringAsFixed(1)}m',
                style: AppTextStyles.numeric.copyWith(
                  color: AppTokens.goldPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          // Search input
          TextField(
            style: const TextStyle(color: AppTokens.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: const TextStyle(color: AppTokens.textDisabled),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTokens.textSecondary),
              filled: true,
              fillColor: AppTokens.bgElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                borderSide: const BorderSide(color: AppTokens.borderSubtle),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12.0),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'GK', 'DEF', 'MID', 'FWD'].map((pos) {
                final isSelected = _selectedPosition == pos;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(pos),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPosition = pos;
                      });
                    },
                    backgroundColor: AppTokens.bgElevated,
                    selectedColor: AppTokens.neonPrimary.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTokens.neonPrimary : AppTokens.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.0,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTokens.neonPrimary : AppTokens.borderSubtle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12.0),
          // Candidate list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No candidates found within budget',
                      style: AppTextStyles.body.copyWith(color: AppTokens.textDisabled),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                    itemBuilder: (context, idx) {
                      final p = filtered[idx];
                      return PlayerCard(
                        webName: p.webName,
                        positionText: p.position,
                        teamShortName: 'Club ${p.clubId}',
                        nowCostTenths: p.priceTenths,
                        purchasePriceTenths: p.priceTenths,
                        onTap: () {
                          widget.onCandidateSelected(p);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
